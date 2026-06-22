import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String _baseUrl = 'https://api.baserow.io/api/database/rows/table';
  const String _token = 'cEruEiUFkFtmiJ63GLMuBOWFmgdh5wu5';
  const String postsTableId = '812614';
  
  final res = await http.get(
    Uri.parse('$_baseUrl/$postsTableId/?user_field_names=true&size=100&order_by=-DataHora'),
    headers: {'Authorization': 'Token $_token'},
  );
  
  final data = json.decode(utf8.decode(res.bodyBytes));
  if (res.statusCode != 200) {
    print('Error: ${res.body}');
    return;
  }
  final results = data['results'] as List;
  for (var row in results) {
    final desc = row['DescricaoPost'] ?? '';
    if (desc.contains('Seu mood é RIZZ')) {
      print('FOUND POST:');
      print('id: ${row['id']}');
      print('idPostagemInstagram: ${row['idPostagemInstagram']}');
      print('field_7028349: ${row['field_7028349']}');
    }
  }
}
