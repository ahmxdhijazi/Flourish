import os
from flask import Flask, jsonify, request
from werkzeug.utils import secure_filename
#Import the Roboflow library
from inference_sdk import InferenceHTTPClient


# Where to save images (uploads folder)
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

# 2. Connect to your workflow
# This is your secret key. Keep it safe!
client = InferenceHTTPClient(
    api_url="https://serverless.roboflow.com",
    api_key="LaBWh5S4iE3MK8jxMqfY"
)

# 3. Create the Flask app (your "server")
app = Flask(__name__)
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
    return jsonify({ "message": "Hello! This fire ah API kitchen is open frfr!" })


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
            # D. Run your workflow on the saved image
            result = client.run_workflow(
                workspace_name="wecooked2026",
                workflow_id="detect-and-classify",
                images={
                    "image": image_path  # Pass the path to the saved file
                },
                use_cache=True
            )
            
            # E. Clean up the uploaded file after
            os.remove(image_path)

            # F. Send the Roboflow result back to your app!
            return jsonify(result)

        except Exception as e:
            # Clean up the file even if there's an error
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