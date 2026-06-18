import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../modules/dashboard/models/content_model.dart';

class BaserowService {
  static const String _baseUrl = 'https://api.baserow.io/api/database/rows/table';
  static const String _token = 'E2toEerbjIyYZppn6uNxK5D9cbb5ITMb';
  
  static const String accountsTableId = '820734'; // Tabela de Empresas
  static const String postsTableId = '812614';
  static const String templatesTableId = '862226';

  Future<List<AccountModel>> fetchAccounts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$accountsTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List results = decoded['results'] ?? [];
      return results.map((json) => AccountModel.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar as contas do Baserow: ${response.statusCode}');
    }
  }

  Future<List<ContentModel>> fetchPosts(List<AccountModel> accounts) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$postsTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List results = decoded['results'] ?? [];
      return results.map((json) => ContentModel.fromJson(json, accounts)).toList();
    } else {
      throw Exception('Falha ao carregar os posts do Baserow: ${response.statusCode}');
    }
  }

  Future<ContentModel> fetchPost(int postId, List<AccountModel> accounts) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$postsTableId/$postId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return ContentModel.fromJson(decoded, accounts);
    } else {
      throw Exception('Falha ao carregar o post do Baserow: ${response.statusCode}');
    }
  }

  Future<int> createPostRow() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$postsTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return decoded['id'] as int;
    } else {
      throw Exception('Falha ao criar o post no Baserow: ${response.statusCode}');
    }
  }

  Future<List<TemplateModel>> fetchTemplates() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$templatesTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List results = decoded['results'] ?? [];
      return results.map((json) => TemplateModel.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar os templates do Baserow: ${response.statusCode}');
    }
  }
}
