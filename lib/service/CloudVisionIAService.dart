import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudVisionIAService {
  Future<bool> isAnimalImageService(String imageUrl) async {
    final response = await http.post(
      Uri.parse(
          'https://vision.googleapis.com/v1/images:annotate?key={you_key}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requests': [
          {
            'image': {
              'source': {'imageUri': imageUrl}
            },
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10}
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse.containsKey('responses') &&
          jsonResponse['responses'].isNotEmpty &&
          jsonResponse['responses'][0].containsKey('labelAnnotations')) {
        final labels = jsonResponse['responses'][0]['labelAnnotations'] as List;

        // Verificando se a resposta contém rótulos que indicam a presença de um animal.
        for (final label in labels) {
          final description = label['description'].toString().toLowerCase();
          if (description.contains('animal') || description.contains('pet')) {
            return true;
          }
        }
      }

      // Se nenhum rótulo indicar a presença de um animal, retornamos falso.
      return false;
    } else {
      throw Exception('Erro na solicitação ao Cloud Vision API');
    }
  }

  static Future getPredominantColor(String imageUrl) async {
    final response = await http.post(
      Uri.parse('https://vision.googleapis.com/v1/images:annotate?key={you_key}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'requests': [
          {
            'image': {
              'source': {'imageUri': imageUrl}
            },
            'features': [
              {'type': 'IMAGE_PROPERTIES'}
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      final colors = jsonResponse['responses'][0]['imagePropertiesAnnotation']
          ['dominantColors']['colors'] as List;

      if (colors.isNotEmpty) {
        final predominantColor = colors[0];

        final colorHex = predominantColor['color'];

        return colorHex;
      } else {
        return 'Nenhuma cor predominante encontrada.';
      }
    } else {
      throw Exception('Erro na solicitação ao Cloud Vision API');
    }
  }
}
