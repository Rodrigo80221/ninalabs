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

  Future<void> createAccount({
    required String name,
    required String informacoes,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$accountsTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Name': name,
        'InformacoesDaEmpresa': informacoes,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Falha ao criar empresa no Baserow: ${response.statusCode}');
    }
  }

  Future<void> updateAccount(int id, {
    required String name,
    required String informacoes,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$accountsTableId/$id/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Name': name,
        'InformacoesDaEmpresa': informacoes,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Falha ao atualizar empresa no Baserow: ${response.statusCode}');
    }
  }

  Future<List<ContentModel>> fetchPosts(List<AccountModel> accounts) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$postsTableId/?user_field_names=true&order_by=-DataHora'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List results = decoded['results'] ?? [];
      
      final Set<int> neededScheduleIds = {};
      for (var json in results) {
        final idPostagemList = json['idPostagemInstagram'] ?? json['field_7028349'];
        if (idPostagemList != null) {
          int? parsedLinkedScheduleId;
          if (idPostagemList is List && idPostagemList.isNotEmpty) {
            parsedLinkedScheduleId = idPostagemList.first['id'];
          } else if (idPostagemList is String && idPostagemList.trim().isNotEmpty) {
            parsedLinkedScheduleId = int.tryParse(idPostagemList.trim());
          } else if (idPostagemList is int) {
            parsedLinkedScheduleId = idPostagemList;
          }
          if (parsedLinkedScheduleId != null) {
            neededScheduleIds.add(parsedLinkedScheduleId);
          }
        }
      }

      final schedules = await _fetchSchedulesByIds(neededScheduleIds.toList());

      return results.map((json) => ContentModel.fromJson(json, accounts, schedules)).toList();
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
      
      final Set<int> neededScheduleIds = {};
      final idPostagemList = decoded['idPostagemInstagram'] ?? decoded['field_7028349'];
      if (idPostagemList != null) {
        int? parsedLinkedScheduleId;
        if (idPostagemList is List && idPostagemList.isNotEmpty) {
          parsedLinkedScheduleId = idPostagemList.first['id'];
        } else if (idPostagemList is String && idPostagemList.trim().isNotEmpty) {
          parsedLinkedScheduleId = int.tryParse(idPostagemList.trim());
        } else if (idPostagemList is int) {
          parsedLinkedScheduleId = idPostagemList;
        }
        if (parsedLinkedScheduleId != null) {
          neededScheduleIds.add(parsedLinkedScheduleId);
        }
      }
      final schedules = await _fetchSchedulesByIds(neededScheduleIds.toList());

      return ContentModel.fromJson(decoded, accounts, schedules);
    } else {
      throw Exception('Falha ao carregar o post do Baserow: ${response.statusCode}');
    }
  }

  Future<List<ScheduleModel>> _fetchSchedulesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    final List<ScheduleModel> schedules = [];
    
    await Future.wait(ids.map((id) async {
       try {
         final res = await http.get(
           Uri.parse('$_baseUrl/$schedulesTableId/?user_field_names=true&filter__field_4470004__equal=$id'),
           headers: {'Authorization': 'Token $_token'},
         );
         if (res.statusCode == 200) {
           final data = json.decode(utf8.decode(res.bodyBytes));
           if (data['results'] != null && (data['results'] as List).isNotEmpty) {
             schedules.add(ScheduleModel.fromJson(data['results'].first));
             return;
           }
         }
         
         // Fallback: the user might have entered the internal ID instead of id_row
         final fallbackRes = await http.get(
           Uri.parse('$_baseUrl/$schedulesTableId/$id/?user_field_names=true'),
           headers: {'Authorization': 'Token $_token'},
         );
         if (fallbackRes.statusCode == 200) {
           final fallbackData = json.decode(utf8.decode(fallbackRes.bodyBytes));
           schedules.add(ScheduleModel.fromJson(fallbackData));
         }
       } catch (_) {}
    }));
    
    return schedules;
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
      bodyData['idInstagram'] = [idInstagramLinked];
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

  Future<void> createTemplate({
    required String name,
    required String regras,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$templatesTableId/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Name': name,
        'Regras': regras,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Falha ao criar template no Baserow: ${response.statusCode}');
    }
  }

  Future<void> updateTemplate(int id, {
    required String name,
    required String regras,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/$templatesTableId/$id/?user_field_names=true'),
      headers: {
        'Authorization': 'Token $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Name': name,
        'Regras': regras,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Falha ao atualizar template no Baserow: ${response.statusCode}');
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
      Uri.parse('$_baseUrl/$schedulesTableId/?user_field_names=true&size=200&order_by=-id_row'),
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
