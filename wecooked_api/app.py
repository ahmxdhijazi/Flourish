import os
from flask import Flask, jsonify, request
from werkzeug.utils import secure_filename
from inference_sdk import InferenceHTTPClient
from dotenv import load_dotenv  # <-- Import dotenv
import logging  # <-- Import logging

# Load environment variables from .env file (like your API key)
load_dotenv()

# Set up basic logging so you can see errors in your server's console
logging.basicConfig(level=logging.INFO)

# Get the API key from the environment, not hard-coded
ROBOFLOW_API_KEY = os.getenv("ROBOFLOW_API_KEY")
if not ROBOFLOW_API_KEY:
    logging.warning("ROBOFLOW_API_KEY not found in .env file. Server may fail.")
    # You could raise an error here to stop the server if you prefer
    # raise ValueError("No ROBOFLOW_API_KEY set. Halting.")

# Where to save uploaded images
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

# 2. Connect to your workflow
# This is your secret key. Keep it safe!
client = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key=ROBOFLOW_API_KEY  # <-- Use the variable
)

# 3. Create the Flask app (your "server")
app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# A helper function to check file extensions
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

# Create a simple "test" route
@app.route("/")
def hello_world():
    # This just proves the server is on
    return jsonify({ "message": "THE KITCHEN IS OPEN FOR COOKING YESSIRSKI!!!" })


# 5. Create the "analyze" route (this is the real one)
@app.route("/analyze", methods=['POST'])
def analyze_image():
    # A. Check if a file was even sent
    if 'image' not in request.files:
        logging.info("Analyze attempt failed: No image file provided")
        return jsonify({ "error": "No image file provided" }), 400

    file = request.files['image']

    # Check if the file is valid
    if file.filename == '':
        logging.info("Analyze attempt failed: No selected file")
        return jsonify({ "error": "No selected file" }), 400

    if file and allowed_file(file.filename):
        # C. Save the file securely
        filename = secure_filename(file.filename)
        image_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(image_path)
        
        logging.info(f"Image saved to {image_path}, sending to Roboflow...")

        try:
            # Run your workflow on the saved image
            result = client.run_workflow(
                workspace_name="wecooked2026",
                workflow_id="detect-and-classify",
                images={
                    "image": image_path  # Pass the path to the saved file
                },
                use_cache=True
            )
            
            # Clean up the uploaded file after
            os.remove(image_path)
            logging.info(f"Successfully analyzed {filename}. Cleaning up.")

            # Send the Roboflow result back to your app!
            return jsonify(result)

        except Exception as e:
            # Clean up the file even if there's an error
            # Check if file still exists before trying to remove
            if os.path.exists(image_path):
                os.remove(image_path)
            
            logging.error(f"Error during inference for {filename}: {e}", exc_info=True)
            return jsonify({ "error": "Internal server error during analysis", "details": str(e) }), 500

    else:
        logging.info(f"Analyze attempt failed: File type not allowed ({file.filename})")
        return jsonify({ "error": "File type not allowed" }), 400


# This line just makes the "flask run" command work
if __name__ == '__main__':
    # Make sure the 'uploads' folder exists
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    
    # Get port from environment or default to 5000
    port = int(os.getenv('PORT', 5000))
    
    app.run(debug=True, host='0.0.0.0', port=port)