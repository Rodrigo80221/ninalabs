import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/services/baserow_service.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/models/content_model.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_quill/flutter_quill.dart';

class ContentPlanningPage extends StatefulWidget {
  final TemplateModel template;
  final AccountModel? account;

  const ContentPlanningPage({
    super.key,
    required this.template,
    this.account,
  });

  @override
  State<ContentPlanningPage> createState() => _ContentPlanningPageState();
}

class _ContentPlanningPageState extends State<ContentPlanningPage> {
  final BaserowService _baserowService = BaserowService();
  bool _isLoading = false;
  bool _isPlanningWithAI = false;
  String? _iaComment;
  
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  DateTime? _startDate;
  String _selectedPeriod = '7';
  
  final List<String> _periods = List.generate(90, (i) => (i + 1).toString());
  
  List<DateTime> _generatedDates = [];
  Map<String, TextEditingController> _controllers = {};
  final TextEditingController _aiNotesController = TextEditingController();
  
  List<String> _diasPublicacao = [];
  String? _horarioPublicacao;

  final List<String> _months = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ];

  final List<String> _weekdays = [
    'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 
    'Sexta-feira', 'Sábado', 'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _parseDiasPublicacao();
    _loadExistingPlan();
  }

  void _parseDiasPublicacao() {
    if (widget.template.regras != null && widget.template.regras!.isNotEmpty) {
      try {
        final Map<String, dynamic> regrasMap = jsonDecode(widget.template.regras!);
        final dias = regrasMap['diasPublicacao'];
        if (dias is List) {
          _diasPublicacao = dias.map((e) => e.toString()).toList();
        } else if (dias is String && dias.isNotEmpty) {
          _diasPublicacao = [dias];
        }
        final horario = regrasMap['horarioPublicacao'];
        if (horario != null && horario.toString().isNotEmpty) {
          _horarioPublicacao = horario.toString();
        }
      } catch (e) {
        debugPrint('Erro ao parsear diasPublicacao: $e');
      }
    }
  }

  void _loadExistingPlan() {
    if (widget.template.planejamentoDeConteudo != null && widget.template.planejamentoDeConteudo!.isNotEmpty) {
      try {
        final Map<String, dynamic> plan = jsonDecode(widget.template.planejamentoDeConteudo!);
        if (plan.containsKey('startDate') && plan['startDate'] != null) {
          _startDate = DateTime.tryParse(plan['startDate']);
        }
        if (plan.containsKey('period') && _periods.contains(plan['period'])) {
          _selectedPeriod = plan['period'];
        }
        
        if (_startDate != null) {
          _generateDates();
        }
        
        if (plan.containsKey('ideas')) {
          final ideas = plan['ideas'] as Map<String, dynamic>;
          for (var date in _generatedDates) {
            final key = date.toIso8601String().split('T').first;
            if (ideas.containsKey(key)) {
              _controllers[key]?.text = ideas[key].toString();
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao parsear planejamentoDeConteudo: $e');
      }
    }
  }

  int _getDaysForPeriod(String period) {
    return int.tryParse(period) ?? 7;
  }

  bool _isDayAllowed(DateTime date) {
    if (_diasPublicacao.isEmpty) return true; // Se não tem regra, permite todos
    
    // Mapear o weekday do DateTime (1 = Segunda, 7 = Domingo) 
    // para a string de `diasPublicacao` (ex: "Segunda", "Terça", etc).
    final Map<int, String> dayMap = {
      1: 'Segunda',
      2: 'Terça',
      3: 'Quarta',
      4: 'Quinta',
      5: 'Sexta',
      6: 'Sábado',
      7: 'Domingo',
    };
    
    final dayStr = dayMap[date.weekday];
    return _diasPublicacao.contains(dayStr);
  }

  void _generateDates() {
    if (_startDate == null) return;

    final int totalDays = _getDaysForPeriod(_selectedPeriod);
    
    // Salva o texto atual para não perder
    Map<String, String> existingTexts = {};
    _controllers.forEach((key, controller) {
      existingTexts[key] = controller.text;
    });

    _generatedDates.clear();
    _controllers.clear();

    for (int i = 0; i < totalDays; i++) {
      final current = _startDate!.add(Duration(days: i));
      if (_isDayAllowed(current)) {
        _generatedDates.add(current);
        final key = current.toIso8601String().split('T').first;
        _controllers[key] = TextEditingController(text: existingTexts[key] ?? '');
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final month = _months[date.month - 1];
    final year = date.year;
    final weekday = _weekdays[date.weekday - 1];
    
    String formatted = '$day de $month de $year — $weekday';
    if (_horarioPublicacao != null) {
      formatted += ' às $_horarioPublicacao';
    }
    return formatted;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> ideas = {};
      _controllers.forEach((key, controller) {
        if (controller.text.trim().isNotEmpty) {
          ideas[key] = controller.text.trim();
        }
      });

      final Map<String, dynamic> plan = {
        'startDate': _startDate?.toIso8601String(),
        'period': _selectedPeriod,
        if (_aiNotesController.text.trim().isNotEmpty) 'observacoesParaIA': _aiNotesController.text.trim(),
        if (_iaComment != null && _iaComment!.isNotEmpty) 'iaComment': _iaComment,
        'ideas': ideas,
      };

      await _baserowService.updateTemplate(
        widget.template.id,
        name: widget.template.name,
        regras: widget.template.regras ?? '{}',
        planejamentoDeConteudo: jsonEncode(plan),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planejamento salvo com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createPlanningWithAI() async {
    setState(() {
      _isPlanningWithAI = true;
      _iaComment = null;
    });

    try {
      final Map<String, String> contentIdeas = {};
      for (var date in _generatedDates) {
        final key = date.toIso8601String().split('T').first;
        final currentText = _controllers[key]?.text.trim() ?? '';
        contentIdeas[key] = currentText.isEmpty ? 'Ideia para ${_formatDate(date)}' : currentText;
      }

      String getPlainText(String? text) {
        if (text == null || text.isEmpty) return '';
        try {
          final doc = Document.fromJson(jsonDecode(text));
          return doc.toPlainText().trim();
        } catch (_) {
          return text;
        }
      }

      Map<String, dynamic> formData = {};
      if (widget.template.regras != null && widget.template.regras!.isNotEmpty) {
        try {
          formData = jsonDecode(widget.template.regras!);
        } catch (_) {}
      }

      final templateJson = {
        'nomeTemplate': widget.template.name,
        'formData': formData,
        'identidade': getPlainText(widget.template.identidade),
        'informacoesAdicionais': getPlainText(formData['informacoesAdicionais']?.toString()),
        'usaMusicasDeFundoPreGravadas': widget.template.usaMusicasDeFundoPreGravadas,
      };

      final payload = {
        'observations': _aiNotesController.text,
        'contentIdeas': contentIdeas,
        'templateJson': templateJson,
        'entrepreneurInformation': getPlainText(widget.account?.informacoesDaEmpresa),
      };

      final response = await http.post(
        Uri.parse('https://n8n.progridai.com.br/webhook/ninalabs/planejarconteudo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          bool successParsing = false;
          try {
            print('--- AI RESPONSE START ---');
            print('Raw body: ${response.body}');
            final responseData = jsonDecode(response.body);
            print('Decoded data type: ${responseData.runtimeType}');
            
            Map<String, dynamic>? itemMap;
            
            if (responseData is List && responseData.isNotEmpty) {
              final first = responseData.first;
              if (first is Map) {
                itemMap = Map<String, dynamic>.from(first);
              } else if (first is String) {
                try { itemMap = jsonDecode(first); } catch (_) {}
              }
            } else if (responseData is Map) {
              if (responseData.containsKey('data') && responseData['data'] is List && (responseData['data'] as List).isNotEmpty) {
                 final inner = responseData['data'].first;
                 if (inner is Map) itemMap = Map<String, dynamic>.from(inner);
              } else {
                 itemMap = Map<String, dynamic>.from(responseData);
              }
            } else if (responseData is String) {
              try {
                final innerDecode = jsonDecode(responseData);
                if (innerDecode is List && innerDecode.isNotEmpty && innerDecode.first is Map) {
                  itemMap = Map<String, dynamic>.from(innerDecode.first);
                } else if (innerDecode is Map) {
                  itemMap = Map<String, dynamic>.from(innerDecode);
                }
              } catch (_) {}
            }

            if (itemMap != null) {
              print('Found itemMap keys: ${itemMap.keys.toList()}');
              setState(() {
                itemMap!.forEach((key, value) {
                  if (key == 'IAComment') {
                    _iaComment = value.toString();
                    print('Set IAComment: $_iaComment');
                  } else {
                    if (_controllers.containsKey(key)) {
                      _controllers[key]?.text = value.toString();
                      print('Updated controller for $key');
                    } else {
                      print('Key $key not found in controllers. Available keys: ${_controllers.keys.toList()}');
                    }
                  }
                });
              });
              successParsing = true;
            } else {
              print('Data could not be parsed into a Map.');
            }
          } catch (e, stack) {
            print('Erro ao ler resposta da IA: $e\n$stack');
          }
          print('--- AI RESPONSE END ---');

          if (successParsing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Planejamento gerado pela IA com sucesso!'), backgroundColor: Colors.green),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resposta recebida, mas não pôde ser lida. Verifique o console.'), backgroundColor: Colors.orange),
            );
          }
        }
      } else {
        throw Exception('Falha ao enviar: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar para IA: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlanningWithAI = false);
      }
    }
  }

  void _copyJson() {
    final Map<String, dynamic> exportData = {};
    
    if (_aiNotesController.text.trim().isNotEmpty) {
      exportData['ObservacoesParaIA'] = _aiNotesController.text.trim();
    }
    if (_iaComment != null && _iaComment!.isNotEmpty) {
      exportData['IAComment'] = _iaComment;
    }

    for (var date in _generatedDates) {
      final key = date.toIso8601String().split('T').first;
      final currentText = _controllers[key]?.text.trim() ?? '';
      exportData[key] = currentText.isEmpty ? 'Ideia para ${_formatDate(date)}' : currentText;
    }
    
    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    Clipboard.setData(ClipboardData(text: jsonStr));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copiado para a área de transferência!'), backgroundColor: Colors.green),
    );
  }

  void _showImportDialog() {
    final TextEditingController importController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: importController,
            maxLines: 10,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Cole o JSON gerado pela IA aqui',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final Map<String, dynamic> imported = jsonDecode(importController.text);
                setState(() {
                  imported.forEach((key, value) {
                    if (_controllers.containsKey(key)) {
                      _controllers[key]?.text = value.toString();
                    }
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JSON importado com sucesso!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erro ao importar JSON: Verifique o formato.'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
            child: const Text('Importar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _aiNotesController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planejamento - ${widget.template.name}'),
      ),
      bottomNavigationBar: _generatedDates.isNotEmpty && !_isLoading
          ? Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
                    child: const Text('Salvar Planejamento', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : IgnorePointer(
              ignoring: _isPlanningWithAI,
              child: Opacity(
                opacity: _isPlanningWithAI ? 0.6 : 1.0,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                if (_diasPublicacao.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(child: Text('Nenhum dia de publicação definido no template. Todos os dias serão gerados.')),
                      ],
                    ),
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Dias de publicação do template: ${_diasPublicacao.join(", ")}.')),
                      ],
                    ),
                  ),

                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data de Início', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                                _generateDates();
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true, isDense: true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _startDate != null ? _formatDate(_startDate!) : 'Selecione uma data',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.calendar_today, size: 20),
                                ],
                              ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Período', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedPeriod,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, fillColor: Colors.white, filled: true),
                          items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPeriod = val;
                                _generateDates();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: const Text('Planejar com IA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                      childrenPadding: const EdgeInsets.all(16.0),
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Observações para a IA', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _aiNotesController,
                          minLines: 4,
                          maxLines: 15,
                          decoration: InputDecoration(
                            hintText: 'Ex.: criar conteúdos mais educativos, priorizar Reels, evitar temas repetidos...',
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                            fillColor: Colors.white,
                            filled: true,
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isListening ? Colors.red.withOpacity(0.1) : AppColors.surface,
                                ),
                                child: IconButton(
                                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : AppColors.terracotta),
                                  onPressed: () async {
                                    if (!_isListening) {
                                      bool available = await _speechToText.initialize();
                                      if (available) {
                                        setState(() {
                                          _isListening = true;
                                          _lastWords = _aiNotesController.text;
                                        });
                                        _speechToText.listen(
                                          onResult: (result) {
                                            setState(() {
                                              final newText = _lastWords.isEmpty ? result.recognizedWords : '$_lastWords ${result.recognizedWords}';
                                              _aiNotesController.text = newText;
                                              if (result.finalResult) {
                                                _lastWords = newText;
                                                _isListening = false;
                                              }
                                            });
                                          },
                                          localeId: 'pt_BR',
                                        );
                                      }
                                    } else {
                                      setState(() => _isListening = false);
                                      _speechToText.stop();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _isPlanningWithAI ? () {} : _createPlanningWithAI,
                          icon: _isPlanningWithAI
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: Text(_isPlanningWithAI ? 'Planejando...' : 'Criar Planejamento', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
                        ),
                      ),
                      if (_iaComment != null && _iaComment!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade200),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _iaComment!,
                                  style: TextStyle(color: Colors.green.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
                
                if (_generatedDates.isNotEmpty)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 16.0, bottom: 8.0),
                        child: Text('Ideias de Conteúdo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          TextButton.icon(
                            onPressed: _copyJson,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copiar JSON'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
                          ),
                          TextButton.icon(
                            onPressed: _showImportDialog,
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Importar JSON'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
                          ),
                        ],
                      ),
                    ],
                  ),
                
                const SizedBox(height: 16),
                
                ..._generatedDates.map((date) {
                  final key = date.toIso8601String().split('T').first;
                  final controller = _controllers[key];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(date),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            fillColor: Colors.white,
                            filled: true,
                            hintText: 'Descreva a ideia de conteúdo',
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (_startDate != null && _generatedDates.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Nenhum dia de publicação encontrado neste período.', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
    );
  }
}
