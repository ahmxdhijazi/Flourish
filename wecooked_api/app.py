"""
WeCooked API - Food Image Analysis Backend

IMPORTANT: Update these model IDs with your actual Roboflow model IDs!
Find them in your Roboflow dashboard under each model's settings.

Example format: "workspace-name/model-version" (e.g., "wecooked2026/1")
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

DETECTION_MODEL_ID = "plant-growth-stage-detection-ver2/1"  # Object detection model
CLASSIFICATION_MODEL_ID = "car-colors-1smyc/5"  # Classification model

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
        "message": "Hello! This fire ah API kitchen is open frfr!",
        "current_model_ids": {
            "detection": DETECTION_MODEL_ID,
            "classification": CLASSIFICATION_MODEL_ID
        },
        "note": "If you're getting 404 errors, update these model IDs in app.py with your actual Roboflow model IDs"
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
            # D. Use direct model inference instead of workflow
            result = client.infer(image_path, model_id=DETECTION_MODEL_ID)
            
            # E. Clean up the uploaded file after
            os.remove(image_path)

            # F. Send the Roboflow result back to your app!
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
                        "message": "Model not found! You need to update the model ID in app.py",
                        "current_model_id": DETECTION_MODEL_ID,
                    }
                }), 404
            
            return jsonify({ "error": error_message }), 500

    else:
        return jsonify({ "error": "File type not allowed" }), 400


# Alternative endpoint: Detect AND classify sequentially
@app.route("/analyze-full", methods=['POST'])
def analyze_full():
    """
    This endpoint runs both detection and classification
    by calling them one after another
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
            # Step 1: Run detection (find food items)
            detection_result = client.infer(image_path, model_id=DETECTION_MODEL_ID)
            
            # Step 2: Run classification (categorize the food)
            classification_result = client.infer(image_path, model_id=CLASSIFICATION_MODEL_ID)
            
            # Clean up
            os.remove(image_path)

            # Return both results
            return jsonify({
                "detection": detection_result,
                "classification": classification_result
            })

        except Exception as e:
            os.remove(image_path)
            print(f"Error during inference: {e}")
            return jsonify({ "error": str(e) }), 500

    else:
        return jsonify({ "error": "File type not allowed" }), 400


# 6. This line just makes the "flask run" command work
if __name__ == '__main__':
    # Make sure the 'uploads' folder exists
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    app.run(debug=True)