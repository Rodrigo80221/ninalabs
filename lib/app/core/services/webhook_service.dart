import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';

class WebhookService {
  static ApiResponse _parseResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
        return ApiResponse.fromJson(decoded);
      }
    } catch (_) {}
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(success: true, data: response.body);
    } else {
      return ApiResponse(success: false, message: 'Erro na requisição (Status ${response.statusCode})');
    }
  }

  static Future<ApiResponse> continuarProducao({
    required int codigoEmpresa,
    required int codigoContrato,
    required int idRow,
    required DateTime dataAgendamento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.continuarProducao),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigoEmpresa': codigoEmpresa.toString(),
          'codigoContrato': codigoContrato.toString(),
          'idRow_InformarAquiRegistroDaTabelaHistoricoCriacaoDeRews': idRow.toString(),
          'ApenasGerarIdeia?': false,
          'DataAgendamentoInstagram': dataAgendamento.toIso8601String(),
        }),
      );

      final apiResponse = _parseResponse(response);
      if (!apiResponse.success) {
        debugPrint('Erro Webhook (Status ${response.statusCode}): ${response.body}');
      }
      return apiResponse;
    } catch (e) {
      debugPrint('Erro Exception Webhook: $e');
      return ApiResponse(success: false, message: 'Falha ao conectar: $e');
    }
  }

  static Future<ApiResponse> criarNovoPost({
    required int codigoEmpresa,
    required int codigoContrato,
    required int idRow,
    required DateTime dataAgendamento,
    bool apenasGerarIdeia = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.criarNovoPost),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigoEmpresa': codigoEmpresa.toString(),
          'codigoContrato': codigoContrato.toString(),
          'idRow_InformarAquiRegistroDaTabelaHistoricoCriacaoDeRews': idRow.toString(),
          'ApenasGerarIdeia?': apenasGerarIdeia,
          'DataAgendamentoInstagram': dataAgendamento.toIso8601String(),
        }),
      );

      final apiResponse = _parseResponse(response);
      if (!apiResponse.success) {
        debugPrint('Erro Webhook criarNovoPost (Status ${response.statusCode}): ${response.body}');
      }
      return apiResponse;
    } catch (e) {
      debugPrint('Erro Exception Webhook criarNovoPost: $e');
      return ApiResponse(success: false, message: 'Falha ao conectar: $e');
    }
  }
}
