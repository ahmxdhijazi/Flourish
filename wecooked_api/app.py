"""
WeCooked API - Plant Growth Stage Detection Backend

Detects plant growth stages using Roboflow's plant-growth-stage-detection-ver2 model.
Model detects: seedling, vegetative, flowering, and fruiting stages.
"""

import os
import requests #delivery driver firebase URLS
import uuid #creating unique filenames
import logging #logging errors, see whats happening
from flask import Flask, jsonify, request
from flask_cors import CORS
#Import the Roboflow library
from inference_sdk import InferenceHTTPClient

# Load environment variables from a local .env file if python-dotenv is available.
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass


# Configuration
logging.basicConfig(level=logging.INFO)
UPLOAD_FOLDER = 'uploads'

# Plant growth stage detection model from Roboflow Universe
PLANT_DETECTION_MODEL_ID = "plant-growth-stage-detection-ver2/1"
DISEASE_DETECTION_MODEL_ID = "plant-disease-detection-qidwz/4"

# Roboflow Workflows (if you want to use workflows instead of models)
WORKFLOW_1_ID = "detect-and-classify"  # First workflow
WORKFLOW_2_ID = "detect-and-classify-2"  # Second workflow (Detect and Classify 2)
WORKSPACE_NAME = "wecooked2026"

# 2. Connect to your workflow
# The API key is read from the environment - never hard-code or commit it.
# Set ROBOFLOW_API_KEY in a local .env file (see .env.example) or export it.
ROBOFLOW_API_KEY = os.getenv("ROBOFLOW_API_KEY")
if not ROBOFLOW_API_KEY:
    raise RuntimeError(
        "ROBOFLOW_API_KEY is not set. Copy .env.example to .env and add your key, "
        "or export ROBOFLOW_API_KEY before starting the server."
    )

client = InferenceHTTPClient(
    api_url=os.getenv("ROBOFLOW_API_URL", "https://serverless.roboflow.com"),
    api_key=ROBOFLOW_API_KEY,
)

# 3. Create the Flask app (your "server")
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# A helper function to check file extensions REPLACED
def download_image_from_url(image_url):
    try:
        response = requests.get(image_url, stream = True)
        response.raise_for_status() #error on bad response

        #get the file extension
        content_type = response.headers.get('content-type', '')
        if'image/jpeg' in content_type:
            ext = '.jpg'
        elif 'image/png' in content_type:
            ext = '.png'
        else:
            ext = 'jpg' #default to jpg if unknown
        
        #create a unique filename, secure filename in uploads folder
        filename = f"{uuid.uuid4()}{ext}"
        image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        #save downloaded image to uploads folder
        with open(image_path, 'wb') as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)
        
        logging.info(f"Image downloaded and saved to {image_path}")
        return image_path, None #returns path and no error
    except requests.exceptions.RequestException as e:
        logging.error(f"Error saving file: {e}")
        return None, (jsonify({ "error": "Failed to save downloaded file", "details": str(e) }), 500) #returns no path and the error message

# --- API ROUTES (The "Menu") ---

# 4. Create a simple "test" route
@app.route("/")
def hello_world():
    # This just proves the server is on
    return jsonify({ 
        "message": "Plant Growth Stage Detection API is running!",
        "model": PLANT_DETECTION_MODEL_ID,
        "detectable_stages": ["seedling", "vegetative", "flowering", "fruiting"],
        "status": "ready"
    })


# 5. Create the "analyze" route (this is the real one)
@app.route("/analyze", methods=['POST'])
def analyze_image():
    #check if we got a JSON payload with image_url
    try:
        data = request.json
        if not data or 'imageURL' not in data:
            logging.info("Analyze attempt failed: No 'imageUrl' in JSON body")
            return jsonify({ "error": "No 'image_url' key provided in JSON body" }), 400
        
        image_url = data['imageURL']
        logging.info(f"Received request to analyze URL: {image_url}")

    except Exception as e:
        logging.error(f"Error parsing JSON body: {e}")
        return jsonify({ "error": "Invalid JSON body" }), 400
    # Download the image from the provided URL
    image_path, error = download_image_from_url(image_url)
    if error:
        return error
    try:
        # D. Detect plant growth stages
        result = client.infer(image_path, model_id=PLANT_DETECTION_MODEL_ID)
        
        # E. Clean up the uploaded file after
        os.remove(image_path)

        # F. Send the results back to your app!
        return jsonify(result)

    except Exception as e:
        # Clean up the file even if there's an error
        if os.path.exists(image_path):
            os.remove(image_path)
        
        error_message = str(e)
        print(f"Error during inference: {error_message}")
        
        # Provide helpful error message for 404
        if "404" in error_message or "not found" in error_message.lower():
            return jsonify({ 
                "error": error_message,
                "help": {
                    "message": "Model not found! Check that the plant detection model is accessible.",
                    "current_model_id": PLANT_DETECTION_MODEL_ID,
                }
            }), 404
        
        return jsonify({ "error": error_message }), 500

    else:
        return jsonify({ "error": "File type not allowed" }), 400


# Alternative endpoint: Same as /analyze (kept for backwards compatibility)
@app.route("/analyze-full", methods=['POST'])
def analyze_full():
    """
    Detects plant growth stages (same as /analyze endpoint)
    """
    try:
        data = request.json
        if not data or 'imageURL' not in data:
            logging.info("Analyze attempt failed: No 'imageUrl' in JSON body")
            return jsonify({ "error": "No 'image_url' key provided in JSON body" }), 400
        
        image_url = data['imageURL']
        logging.info(f"Received request to analyze URL: {image_url}")
    
    except Exception as e:
        logging.error(f"Error parsing JSON body: {e}")
        return jsonify({ "error": "Invalid JSON body" }), 400


    # Download the image from the provided URL
    image_path, error = download_image_from_url(image_url)
    if error:
        return error
    
    try:
        # Detect plant growth stages
        result = client.infer(image_path, model_id=PLANT_DETECTION_MODEL_ID)
        
        # Clean up
        os.remove(image_path)

        # Return results
        return jsonify(result)

    except Exception as e:
        os.remove(image_path)
        print(f"Error during inference: {e}")
        return jsonify({ "error": str(e) }), 500

    else:
        return jsonify({ "error": "File type not allowed" }), 400

# New endpoint: Run two MODELS on the same image (more reliable than workflows)
@app.route("/analyze-dual-model", methods=['POST'])
def analyze_dual_model():
    """
    Runs the same image through TWO different Roboflow models
    and returns both results (more reliable than workflows)
    """
    # A. Check if we got a JSON payload with a URL
    try:
        data = request.json
        if not data or 'imageURL' not in data:
            logging.info("Analyze-dual-model attempt failed: No 'imageURL' in JSON body")
            return jsonify({ "error": "No 'imageURL' key provided in JSON body" }), 400
        
        image_url = data['imageURL']
        logging.info(f"Received request to analyze-dual-model URL: {image_url}")

    except Exception as e:
        logging.error(f"Error parsing JSON: {e}")
        return jsonify({ "error": "Invalid JSON body" }), 400

    # B. Download the image from the URL
    image_path, error = download_image_from_url(image_url)
    if error:
        return error # Return the error message if download failed

    # C. Run analysis
    MODEL_1_ID = PLANT_DETECTION_MODEL_ID
    MODEL_2_ID = DISEASE_DETECTION_MODEL_ID
    
    model1_result = None
    model2_result = None
    errors = {}

    try:
        # Run first model
        logging.info(f"Running model 1: {MODEL_1_ID}")
        model1_result = client.infer(image_path, model_id=MODEL_1_ID)
    except Exception as e:
        logging.error(f"Model 1 error: {e}")
        errors["model1"] = str(e)

    try:
        # Run second model
        logging.info(f"Running model 2: {MODEL_2_ID}")
        model2_result = client.infer(image_path, model_id=MODEL_2_ID)
    except Exception as e:
        logging.error(f"Model 2 error: {e}")
        errors["model2"] = str(e)

    # Clean up
    os.remove(image_path)

    # Return both results
    return jsonify({
        "model1": {
            "id": MODEL_1_ID,
            "result": model1_result,
            "error": errors.get("model1")
        },
        "model2": {
            "id": MODEL_2_ID,
            "result": model2_result,
            "error": errors.get("model2")
        },
        "success": len(errors) == 0
    })


# 6. This line just makes the "flask run" command work
if __name__ == '__main__':
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    port = int(os.getenv("PORT", 5000))
    # Debug mode exposes the Werkzeug interactive debugger (arbitrary code
    # execution) - keep it off unless explicitly enabled for local dev.
    debug = os.getenv("FLASK_DEBUG", "false").lower() in ("1", "true", "yes")
    # Bind to loopback by default. Set HOST=0.0.0.0 to reach it from a phone /
    # emulator on your LAN, and only do that on a trusted network.
    host = os.getenv("HOST", "127.0.0.1")
    app.run(debug=debug, host=host, port=port)