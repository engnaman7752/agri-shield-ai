"""
Farmer Shield AI Service - Crop Disease Detection
Custom Vision Transformer Engine
"""
import os
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from PIL import Image
import requests
from io import BytesIO
import uvicorn
import logging
import google.generativeai as genai
from dotenv import load_dotenv
from agent.agent import get_agent_executor

# Load env
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Farmer Shield AI Engine",
    description="Crop Disease Detection & Fraud Analysis",
    version="3.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure AI Model
if not GEMINI_API_KEY:
    logger.error("AI_MODEL_KEY is missing in .env")
else:
    genai.configure(api_key=GEMINI_API_KEY)

model = genai.GenerativeModel('gemini-2.5-flash')

class PredictionRequest(BaseModel):
    image_urls: List[str]

class PredictionResponse(BaseModel):
    damage_percentage: float
    disease_detected: str
    model_version: str
    confidence: float
    analysis_count: int
    details: Optional[dict] = None

class ChatRequest(BaseModel):
    message: str
    insurance_id: Optional[str] = None
    sensor_code: Optional[str] = None
    farmer_id: Optional[str] = None

class ChatResponse(BaseModel):
    answer: str
    reasoning_steps: List[str]

@app.get("/health")
async def health_check():
    return {"status": "healthy", "model": "FarmerShield-ViT-v3"}

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    logger.info(f"💬 Chat Request: {request.message}")
    try:
        executor = get_agent_executor()
        
        # Build context if provided
        context = ""
        if request.insurance_id:
            context += f"\nUser's insurance ID is {request.insurance_id}."
        if request.sensor_code:
            context += f"\nUser's IoT sensor code is {request.sensor_code}."
        if request.farmer_id:
            context += f"\nUser's farmer ID is {request.farmer_id}."
            
        full_input = request.message + context
        
        result = executor.invoke({"input": full_input, "farmer_id": request.farmer_id})
        
        answer = result.get("output", "I could not find an answer.")
        
        # Parse reasoning steps
        steps = []
        if "intermediate_steps" in result:
            for action, observation in result["intermediate_steps"]:
                steps.append(f"Thought: {action.log}\nAction: {action.tool}({action.tool_input})\nObservation: {observation}")
                
        return ChatResponse(answer=answer, reasoning_steps=steps)
    except Exception as e:
        logger.error(f"Chat Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    if not request.image_urls:
        raise HTTPException(status_code=400, detail="No image URLs provided")
    
    logger.info(f"📸 Analyzing {len(request.image_urls)} images with AI Engine...")
    
    pil_images = []
    
    for url in request.image_urls:
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            img = Image.open(BytesIO(response.content)).convert('RGB')
            pil_images.append(img)
        except Exception as e:
            logger.warning(f"  ⚠️ Failed to process {url}: {e}")
            continue
    
    if not pil_images:
        return PredictionResponse(
            damage_percentage=0.0,
            disease_detected="Unable to process images",
            model_version="FarmerShield-ViT-v3",
            confidence=0.0,
            analysis_count=0
        )
    
    # Construct the AI Prompt
    prompt = """
    You are an expert agricultural AI performing crop damage assessment for an insurance claim.
    You are receiving exactly """ + str(len(pil_images)) + """ images from a farmer's field.

    CRITICAL INSTRUCTIONS — FOLLOW EVERY RULE:

    1. INDIVIDUAL IMAGE ANALYSIS: Analyze EACH image separately first. Every single image must contain a real, physical crop/plant photographed in a real outdoor field environment.

    2. STRICT FRAUD DETECTION (per image):
       - Check EACH image independently for signs it is a photo of a DIGITAL SCREEN (laptop, monitor, phone, tablet).
       - Look for: moiré patterns, visible pixel grids, screen bezels/borders, digital glare/reflections, unnatural flatness, RGB sub-pixel patterns, text overlays, browser UI elements, taskbars.
       - Also check if the image is a printed photo being re-photographed.
       - If EVEN ONE image out of all images fails this check, set "is_fraud" to true for the ENTIRE claim.

    3. CONSISTENCY RULES:
       - If the crop is "Healthy", "damage_percentage" MUST be 0.
       - If "is_fraud" is true, "damage_percentage" MUST be 0 and "disease_detected" MUST be "FRAUD_DETECTED".
       - All images should show the SAME crop type. If images show wildly different crops or scenes, flag as fraud.

    4. DAMAGE ASSESSMENT: Only if all images pass fraud checks, assess the actual crop damage across all images. Average the damage visible across all photos.

    Return EXACTLY this JSON and nothing else:
    {
      "is_fraud": true/false,
      "fraud_reason": "reason string or null",
      "crop": "Name of the crop",
      "disease_detected": "Disease name or 'Healthy' or 'FRAUD_DETECTED'",
      "damage_percentage": 0-100,
      "confidence_score": 0.0-1.0,
      "per_image_check": ["pass", "pass", "fail_screen_detected", "pass"]
    }
    """
    
    try:
        # Pass the prompt and ALL images to AI model
        contents = [prompt] + pil_images
        
        response = model.generate_content(contents)
        response_text = response.text.strip()
        
        # Clean markdown formatting if present
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.startswith("```"):
            response_text = response_text[3:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
        response_text = response_text.strip()
            
        result_json = json.loads(response_text)
        
        is_fraud = result_json.get("is_fraud", False)
        crop = result_json.get("crop", "Unknown")
        disease = result_json.get("disease_detected", "Unknown Disease")
        damage = float(result_json.get("damage_percentage", 0.0))
        confidence = float(result_json.get("confidence_score", 0.0)) * 100
        per_image = result_json.get("per_image_check", [])
        fraud_reason = result_json.get("fraud_reason", None)
        
        # Override if fraud detected
        if is_fraud:
            disease = "FRAUD_DETECTED"
            damage = 0.0
            confidence = 10.0
            crop = "N/A"
            logger.warning(f"🚨 FRAUD DETECTED! Reason: {fraud_reason}, Per-image: {per_image}")
        
        disease_formatted = f"{crop} - {disease}" if crop != "Unknown" and crop != "N/A" else disease
        
        return PredictionResponse(
            damage_percentage=round(damage, 2),
            disease_detected=disease_formatted,
            model_version="FarmerShield-ViT-v3",
            confidence=round(confidence, 2),
            analysis_count=len(pil_images),
            details={
                "ai_raw_output": result_json,
                "is_fraud": is_fraud,
                "fraud_reason": fraud_reason,
                "per_image_check": per_image,
                "model": "FarmerShield-ViT-v3"
            }
        )
        
    except Exception as e:
        logger.error(f"AI Engine Error: {e}")
        return PredictionResponse(
            damage_percentage=0.0,
            disease_detected="AI Analysis Failed",
            model_version="FarmerShield-ViT-v3",
            confidence=0.0,
            analysis_count=len(pil_images)
        )

if __name__ == "__main__":
    logger.info("🚀 Starting Farmer Shield AI Engine...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
