import os
import google.generativeai as genai
from agent.tools import get_weather, get_sensor_data, pmfby_rag_search, get_policy_details, get_pest_control_advice, calculate_premium, get_crop_calendar, apply_for_insurance, get_all_farmer_policies

# Configure Gemini
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

class CustomAgentExecutor:
    def __init__(self):
        self.tools_list = [
            get_weather, get_sensor_data, pmfby_rag_search, 
            get_policy_details, get_pest_control_advice, 
            calculate_premium, get_crop_calendar, apply_for_insurance,
            get_all_farmer_policies
        ]
        self.model = genai.GenerativeModel(
            model_name='gemini-2.5-flash',
            tools=self.tools_list,
            system_instruction="You are a helpful AI assistant for the Farmer Shield app. Always use your available tools if you need real-time or specific data like policies, sensor data, or weather. If the user asks to apply for insurance, you MUST use the apply_for_insurance tool. Ask them for their khasra number, crop type, area in acres, and their location (latitude and longitude) if they haven't provided it. If the user asks for all their policies, use get_all_farmer_policies. Use the farmer_id provided in the context."
        )
    
    def invoke(self, inputs):
        question = inputs.get("input", "")
        
        try:
            chat = self.model.start_chat(enable_automatic_function_calling=True)
            response = chat.send_message(question)
            
            # Extract reasoning steps from chat history
            steps = []
            for msg in chat.history:
                if hasattr(msg, "parts"):
                    for part in msg.parts:
                        if hasattr(part, "function_call") and part.function_call:
                            tool_name = part.function_call.name
                            args = dict(part.function_call.args)
                            steps.append((type('Action', (), {'log': f'Decided to use tool {tool_name}...', 'tool': tool_name, 'tool_input': str(args)})(), 'Waiting for backend data...'))
                        elif hasattr(part, "function_response") and part.function_response:
                            resp = dict(part.function_response.response)
                            steps.append((type('Action', (), {'log': 'Received data from tool', 'tool': 'System', 'tool_input': ''})(), str(resp)))
            
            return {
                "output": response.text,
                "intermediate_steps": steps if steps else [(type('Action', (), {'log': 'Thinking...', 'tool': 'Agent', 'tool_input': 'Analyze'})(), 'Direct response without tools')]
            }
        except Exception as e:
            return {"output": f"Error: {e}"}

def get_agent_executor():
    return CustomAgentExecutor()
