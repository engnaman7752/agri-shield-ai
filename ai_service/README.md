# 🤖 Farmer Shield AI Service

Crop Disease Detection using **ResNet50** pretrained on **PlantVillage** dataset.

## Model Info
- **Architecture**: ResNet-50 (50-layer Residual Network)
- **Dataset**: PlantVillage (54,000+ images, 38 classes)
- **Accuracy**: ~98.7% on validation set
- **Classes**: 38 crop disease categories

## Quick Start

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Run Service
```bash
python main.py
```

Service starts at: `http://localhost:8000`

### 3. API Usage

**Health Check:**
```bash
curl http://localhost:8000/health
```

**Predict Disease:**
```bash
curl -X POST http://localhost:8000/api/predict \
  -H "Content-Type: application/json" \
  -d '{"image_urls": ["http://your-server/uploads/claims/image.jpg"]}'
```

**Response:**
```json
{
  "damage_percentage": 85.0,
  "disease_detected": "Potato - Late blight",
  "model_version": "ResNet50-PlantVillage-v1",
  "confidence": 94.5,
  "analysis_count": 1
}
```

## Swagger Docs
Open `http://localhost:8000/docs` for interactive API documentation.
