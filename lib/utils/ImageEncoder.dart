import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ImageEncoder {
  static Future<String> getImageBase64(XFile image) async {
    final imageBytes = await image.readAsBytes();

    return base64Encode(imageBytes);
  }
}
