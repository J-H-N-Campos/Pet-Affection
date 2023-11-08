import 'package:http/http.dart' as http;

Future<String?> UploadImageToServerService(
    Map<String, dynamic> uploadData) async {
  final url = Uri.parse('http://177.44.248.73/ImageUploadAPI.php');

  try {
    final response = await http.post(url, headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'base64Image': uploadData['base64Image'],
      'type': uploadData['type'],
      'id': uploadData['id'].toString(),
      'token': uploadData['token'],
    });

    if (response.statusCode == 200) {
      String imagePath = response.body;
      return imagePath;
    } else {
      return 'Erro ao enviar a imagem. Código de status: ${response.statusCode}';
    }
  } catch (e) {
    return 'Erro durante o upload: $e';
  }
}
