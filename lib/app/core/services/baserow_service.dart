import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../modules/dashboard/models/content_model.dart';
import '../../modules/dashboard/models/schedule_model.dart';

class BaserowService {
  static const String _baseUrl = 'https://api.baserow.io/api/database/rows/table';
  static const String _token = 'cEruEiUFkFtmiJ63GLMuBOWFmgdh5wu5';
  
  static const String accountsTableId = '820734'; // Tabela de Empresas
  static const String postsTableId = '812614';
  static const String templatesTableId = '862226';
  static const String schedulesTableId = '557294';

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

  Future<List<ContentModel>> fetchPosts(List<AccountModel> accounts, List<ScheduleModel> schedules) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$postsTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List results = decoded['results'] ?? [];
      return results.map((json) => ContentModel.fromJson(json, accounts, schedules)).toList();
    } else {
      throw Exception('Falha ao carregar os posts do Baserow: ${response.statusCode}');
    }
  }

  Future<ContentModel> fetchPost(int postId, List<AccountModel> accounts, List<ScheduleModel> schedules) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$postsTableId/$postId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return ContentModel.fromJson(decoded, accounts, schedules);
    } else {
      throw Exception('Falha ao carregar o post do Baserow: ${response.statusCode}');
    }
  }

  Future<int> createPostRow({
    required DateTime scheduleDate,
    required int companyId,
    required int templateId,
    int? idInstagramLinked,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final scheduleDateString = scheduleDate.toUtc().toIso8601String();

    final bodyData = <String, dynamic>{
      'DataAgendamentoInstagram': scheduleDateString,
      'DataHora': now,
      'idEmpresa': [companyId],
      'idConteudo': [templateId],
    };

    if (idInstagramLinked != null) {
      bodyData['IdInstagram'] = [idInstagramLinked];
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/$postsTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      return decoded['id'] as int;
    } else {
      throw Exception('Falha ao criar o post no Baserow: ${response.statusCode}');
    }
  }

  Future<void> deletePostRow(int postId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$postsTableId/$postId/'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Falha ao excluir o post no Baserow: ${response.statusCode}');
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

  Future<List<ScheduleModel>> fetchSchedules() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$schedulesTableId/?user_field_names=true&size=200'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List results = decoded['results'] ?? [];
      return results.map((json) => ScheduleModel.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar os agendamentos do Baserow: ${response.statusCode} - Body: ${response.body}');
    }
  }
}
