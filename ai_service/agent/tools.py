import os
import requests

def get_vector_store():
    # Mock RAG store since langchain is broken on python 3.14
    return "Mock Store"



def get_weather(lat: float, lon: float) -> str:
    """Gets current weather at the specified latitude and longitude."""
    api_key = "680b7e32cf5ab8c9107aac32c782396a"
    url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric"
    try:
        response = requests.get(url)
        data = response.json()
        temp = data.get("main", {}).get("temp", "Unknown")
        condition = data.get("weather", [{}])[0].get("description", "Unknown")
        return f"Temperature is {temp}°C with {condition}."
    except Exception as e:
        return f"Error fetching weather: {e}"


def get_sensor_data(sensor_code: str) -> str:
    """Gets 7-day IoT sensor data (temperature, humidity, soil moisture) for the given sensor code (e.g., SENS-001)."""
    url = f"http://localhost:8080/api/sensors/{sensor_code}/iot-data"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                return str(data.get("data"))
            return "Failed to parse sensor data."
        return f"Error: Status code {response.status_code}"
    except Exception as e:
        return f"Error connecting to backend: {e}"


def pmfby_rag_search(query: str) -> str:
    """Searches the PMFBY (Pradhan Mantri Fasal Bima Yojana) official guidelines for answers about crop insurance policies, rules, and coverage."""
    return "According to PMFBY guidelines, compensation for localized calamities like hailstorm or landslide is calculated based on the proportion of crop damaged. Notify the insurance company within 72 hours."


def get_policy_details(insurance_id: str) -> str:
    """Gets policy details like crop type, sum insured, premium for a specific insurance policy ID."""
    url = f"http://localhost:8080/api/insurance/{insurance_id}"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            if data.get("success"):
                return str(data.get("data"))
        return f"Could not find policy details for ID {insurance_id}"
    except Exception as e:
        return f"Error: {e}"


def get_pest_control_advice(crop: str, symptom: str) -> str:
    """Provides advice on pest control given a crop name and damage symptoms."""
    # Mock data for phase 3
    return f"For {symptom} on {crop}, it is recommended to apply Neem oil spray or specific organic pesticides as per the agricultural department guidelines."


def calculate_premium(crop_type: str, area_hectares: float) -> str:
    """Calculates the estimated PMFBY premium for a given crop type and area in hectares."""
    # Mock PMFBY calculation (Kharif 2%, Rabi 1.5%, Cash/Horticulture 5%)
    rate = 0.02
    if crop_type.lower() in ["wheat", "gram", "mustard"]:
        rate = 0.015
    elif crop_type.lower() in ["cotton", "sugarcane"]:
        rate = 0.05
    
    sum_insured_per_ha = 50000 # Mock value
    premium = area_hectares * sum_insured_per_ha * rate
    return f"Estimated premium for {area_hectares}ha of {crop_type} is ₹{premium:.2f} (at {rate*100}% rate)."


def get_crop_calendar(crop: str, state: str) -> str:
    """Gets sowing and harvesting times for a crop in a specific state."""
    return f"The standard sowing time for {crop} in {state} is early June, and harvesting is around late September to October."

def apply_for_insurance(farmer_id: str, khasra_number: str, crop_type: str, area_acres: float, latitude: float, longitude: float) -> str:
    """Applies for crop insurance on behalf of the farmer. Use this ONLY when the farmer explicitly wants to buy/apply for insurance and you have collected all required details."""
    if not farmer_id:
        return "Error: farmer_id is missing. I cannot apply for insurance without knowing who you are."
        
    url = f"http://localhost:8080/api/insurance/internal/apply?farmerId={farmer_id}"
    payload = {
        "khasraNumber": khasra_number,
        "cropType": crop_type,
        "areaAcres": area_acres,
        "latitude": latitude,
        "longitude": longitude
    }
    try:
        response = requests.post(url, json=payload, timeout=5)
        if response.status_code == 200:
            data = response.json()
            return f"Success! Insurance application created. Order ID: {data.get('data', {}).get('razorpayOrderId', 'N/A')}. Please navigate to the dashboard to complete the payment."
        else:
            return f"Failed to apply: {response.text}"
    except Exception as e:
        return f"Error connecting to backend: {e}"

def get_all_farmer_policies(farmer_id: str) -> str:
    """Gets a list of all insurance policies (active, pending, claims) associated with the farmer. Gives their policy IDs, crop types, and status."""
    if not farmer_id:
        return "Error: farmer_id is missing."
        
    url = f"http://localhost:8080/api/insurance/internal/policies?farmerId={farmer_id}"
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            policies = data.get("data", [])
            if not policies:
                return "You do not have any insurance policies."
            
            result_lines = ["Here are your insurance policies:"]
            for p in policies:
                result_lines.append(f"- Policy ID: {p.get('id')}, Crop: {p.get('cropType')}, Status: {p.get('status')}")
            return "\n".join(result_lines)
        else:
            return f"Failed to get policies: {response.text}"
    except Exception as e:
        return f"Error connecting to backend: {e}"

# List of all tools
ALL_TOOLS = [
    get_weather,
    get_sensor_data,
    pmfby_rag_search,
    get_policy_details,
    get_pest_control_advice,
    calculate_premium,
    get_crop_calendar,
    apply_for_insurance,
    get_all_farmer_policies
]
