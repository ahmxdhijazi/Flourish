"""
WeCooked API - Plant Growth Stage Detection Backend

Detects plant growth stages using Roboflow's plant-growth-stage-detection-ver2 model.
Model detects: seedling, vegetative, flowering, and fruiting stages.
"""

import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.utils import secure_filename
#Import the Roboflow library
from inference_sdk import InferenceHTTPClient


# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

# Plant growth stage detection model from Roboflow Universe
PLANT_DETECTION_MODEL_ID = "plant-growth-stage-detection-ver2/1"
DISEASE_DETECTION_MODEL_ID = "plant-disease-detection-qidwz/4"

# Roboflow Workflows (if you want to use workflows instead of models)
WORKFLOW_1_ID = "detect-and-classify"  # First workflow
WORKFLOW_2_ID = "detect-and-classify-2"  # Second workflow (Detect and Classify 2)
WORKSPACE_NAME = "wecooked2026"

# 2. Connect to your workflow
# This is your secret key. Keep it safe!
client = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key="LaBWh5S4iE3MK8jxMqfY"
)

# 3. Create the Flask app (your "server")
app = Flask(__name__)
CORS(app)  # Enable CORS for all routes
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# A helper function to check file extensions
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

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
    # A. Check if a file was even sent
    if 'image' not in request.files:
        return jsonify({ "error": "No image file provided" }), 400

    file = request.files['image']

    # B. Check if the file is valid
    if file.filename == '':
        return jsonify({ "error": "No selected file" }), 400

    if file and allowed_file(file.filename):
        # C. Save the file securely
        filename = secure_filename(file.filename)
        image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(image_path)
        
        print(f"Image saved to {image_path}")

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
    if 'image' not in request.files:
        return jsonify({ "error": "No image file provided" }), 400

    file = request.files['image']

    if file.filename == '':
        return jsonify({ "error": "No selected file" }), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(image_path)
        
        print(f"Image saved to {image_path}")

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
    if 'image' not in request.files:
        return jsonify({ "error": "No image file provided" }), 400

    file = request.files['image']

    if file.filename == '':
        return jsonify({ "error": "No selected file" }), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(image_path)
        
        print(f"Image saved to {image_path}")

        MODEL_1_ID = PLANT_DETECTION_MODEL_ID  # First model
        MODEL_2_ID = DISEASE_DETECTION_MODEL_ID  # Second model
        
        model1_result = None
        model2_result = None
        errors = {}

        try:
            # Run first model
            print(f"Running model 1: {MODEL_1_ID}")
            model1_result = client.infer(image_path, model_id=MODEL_1_ID)
        except Exception as e:
            print(f"Model 1 error: {e}")
            errors["model1"] = str(e)

        try:
            # Run second model
            print(f"Running model 2: {MODEL_2_ID}")
            model2_result = client.infer(image_path, model_id=MODEL_2_ID)
        except Exception as e:
            print(f"Model 2 error: {e}")
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

    else:
        return jsonify({ "error": "File type not allowed" }), 400


# 6. This line just makes the "flask run" command work
if __name__ == '__main__':
    # Make sure the 'uploads' folder exists
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    app.run(debug=True)