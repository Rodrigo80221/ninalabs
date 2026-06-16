import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String _baseUrl = 'https://api.baserow.io/api/database/rows/table';
  const String _token = 'E2toEerbjIyYZppn6uNxK5D9cbb5ITMb';
  const String postsTableId = '812614';

  final response = await http.get(
    Uri.parse('$_baseUrl/$postsTableId/?user_field_names=true'),
    headers: {
      'Authorization': 'Token $_token',
    },
  );

  if (response.statusCode == 200) {
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final List results = decoded['results'] ?? [];
    for (var i = 0; i < (results.length > 5 ? 5 : results.length); i++) {
      var json = results[i];
      String img = 'https://via.placeholder.com/400x300/F4DCD6/2C2C2C?text=Sem+Imagem';
      final openingImage = json['ImagemDeAbertura'] ?? json['field_6964823'] as List?;
      if (openingImage != null && openingImage.isNotEmpty) {
        img = openingImage.first['url'] ?? img;
      }
      print('Post $i image url: $img');
    }
  } else {
    print('Failed: ${response.statusCode}');
  }
}

