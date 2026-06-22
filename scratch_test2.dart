import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String _baseUrl = 'https://api.baserow.io/api/database/rows/table';
  const String _token = 'cEruEiUFkFtmiJ63GLMuBOWFmgdh5wu5';
  const String schedulesTableId = '557294';
  
  // We fetch up to 3 pages
  for (int page = 1; page <= 3; page++) {
    final res = await http.get(
      Uri.parse('$_baseUrl/$schedulesTableId/?user_field_names=true&size=200&page=$page'),
      headers: {'Authorization': 'Token $_token'},
    );
    final data = json.decode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200) {
      break;
    }
    final results = data['results'] as List;
    for (var row in results) {
      final desc = row['Descrição'] ?? '';
      if (desc.contains('Seu mood é RIZZ')) {
        print('FOUND SCHEDULE:');
        print('id: ${row['id']}');
        print('id_row: ${row['id_row']}');
        print('Data: ${row['Data da postagem']}');
      }
    }
  }
}
