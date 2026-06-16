import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class WebhookService {
  static Future<bool> continuarProducao({
    required int codigoEmpresa,
    required int codigoContrato,
    required int idRow,
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
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Erro Webhook (Status ${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Erro Exception Webhook: $e');
      return false;
    }
  }
}
