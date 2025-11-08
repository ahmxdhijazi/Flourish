import 'dart:convert'; //For encoding/decoding JSON
import 'dart:io';     //For File objects

import 'package:http/http.dart' as http;       //For making HTTP requests
import 'package:image_picker/image_picker.dart'; //For picking images

class CvService {
  // This is the MENU FOR MY LITTY AH kitchen!
  // 127.0.0.1 is "localhost"
  // This works for macOS, Windows, Linux, and iOS simulators.
  final String _apiUrl = 'http://127.0.0.1:5000/analyze';
  // The image picker instance
  final ImagePicker _picker = ImagePicker();

  //This function opens the user's gallery to pick an image
  //It returns the picked image file, or null if one wasn't picked.
  Future<XFile?> pickImage() async {
    try {
      // Open the gallery
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // This is the "waiter" that takes the order to the kitchen
  // It takes the [imageFile] and returns the JSON String response.
  Future<String> analyzeImage(XFile imageFile) async {
    try {
      //Create the HTTP request
      //We use a "MultipartRequest" because we are sending a file
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      //Attach the image file to the request
      //The 'image' field MUST match the one your Flask server expects:
      //`request.files['image']`
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', //The "field name"
          imageFile.path, //The path to the file
        ),
      );

      //Send the request and wait for the response
      print("Sending request to $_apiUrl...");
      var streamedResponse = await request.send();

      //Get the response from the "kitchen"
      var response = await http.Response.fromStream(streamedResponse);
      print("Response code: ${response.statusCode}");
      print("Response body: ${response.body}");

      //Return the result
      if (response.statusCode == 200) {
        // Parse the JSON and print it beautifully
        var decodedJson = jsonDecode(response.body);
        var prettyJson = const JsonEncoder.withIndent('  ').convert(decodedJson);
        return prettyJson;
      } else {
        //Error from the server
        return "Error from server: ${response.statusCode}\n${response.body}";
      }
    } catch (e) {
      //Error in the app (e.g., no internet, server not running, doodoo device)
      print("Error caught: $e");
      return "Error: Could not connect to server.\nIs 'python app.py' running?\n$e";
    }
  }
}