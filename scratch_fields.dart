import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String token = 'E2toEerbjIyYZppn6uNxK5D9cbb5ITMb';
  final response = await http.get(
    Uri.parse('https://api.baserow.io/api/database/fields/table/812614/'),
    headers: {
      'Authorization': 'Token $token',
    },
  );

  if (response.statusCode == 200) {
    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (decoded is List) {
      for (var field in decoded) {
        print('ID: ${field['id']} - Name: ${field['name']} - Type: ${field['type']}');
      }
    }
  } else {
    print('Failed: ${response.statusCode} - ${response.body}');
  }
}
