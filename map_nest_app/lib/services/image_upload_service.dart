import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Free image hosting service using ImgBB API
/// Completely free - no payment method required
class ImageUploadService {
  // ImgBB API key - Get free key from https://api.imgbb.com/
  // For now using a demo key - you should get your own free key
  static const String _imgbbApiKey = 'c24aabf6ca51b14981226a2056b71926';
  
  /// Upload image to ImgBB (completely free)
  /// Get your free API key from: https://api.imgbb.com/
  static Future<String> uploadImage(File imageFile) async {
    try {
      // Read image file as bytes
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Prepare the request
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['key'] = _imgbbApiKey;
      // ImgBB accepts base64 image directly
      request.fields['image'] = base64Image;
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      
      if (jsonData['success'] == true) {
        return jsonData['data']['url'] as String;
      } else {
        throw Exception('Failed to upload image: ${jsonData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
  
  /// Upload multiple images
  static Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final url = await uploadImage(imageFiles[i]);
        uploadedUrls.add(url);
      } catch (e) {
        print('Failed to upload image $i: $e');
        rethrow;
      }
    }
    
    return uploadedUrls;
  }
}

