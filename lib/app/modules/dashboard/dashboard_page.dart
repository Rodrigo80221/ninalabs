import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import '../../core/components/custom_dropdown.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/social_post_card.dart';
import '../empresas/empresa_form_page.dart';
import '../templates/templates_page.dart';
import 'models/content_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController _controller = DashboardController();
  TimeOfDay _lastSelectedTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  DateTime _getDefaultDate() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, _lastSelectedTime.hour, _lastSelectedTime.minute);
  }

  DateTime _getSuggestedDateForTemplate(String templateName) {
    if (templateName == 'Todos') return _getDefaultDate();
    try {
      final t = _controller.allTemplates.firstWhere((t) => t.name == templateName);
      if (t.regras != null) {
        final map = jsonDecode(t.regras!);
        final dias = map['diasPublicacao'];
        final horario = map['horarioPublicacao'];
        if (dias is List && dias.isNotEmpty && horario is String && horario.isNotEmpty) {
          final timeParts = horario.split(':');
          if (timeParts.length == 2) {
            final h = int.parse(timeParts[0]);
            final m = int.parse(timeParts[1]);
            
            final allowedWeekdays = <int>{};
            for (var dia in dias) {
              if (dia == 'Segunda') allowedWeekdays.add(1);
              if (dia == 'Terça') allowedWeekdays.add(2);
              if (dia == 'Quarta') allowedWeekdays.add(3);
              if (dia == 'Quinta') allowedWeekdays.add(4);
              if (dia == 'Sexta') allowedWeekdays.add(5);
              if (dia == 'Sábado') allowedWeekdays.add(6);
              if (dia == 'Domingo') allowedWeekdays.add(7);
            }
            
            if (allowedWeekdays.isNotEmpty) {
              final now = DateTime.now();
              for (int i = 1; i <= 7; i++) {
                final candidate = now.add(Duration(days: i));
                if (allowedWeekdays.contains(candidate.weekday)) {
                  return DateTime(candidate.year, candidate.month, candidate.day, h, m);
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return _getDefaultDate();
  }

  void _showCreatePostDialog() {
    String? selectedEmpresa = _controller.selectedCompany;
    String selectedTemplate = _controller.selectedTemplate;
    
    DateTime? selectedDate = _getSuggestedDateForTemplate(selectedTemplate);

    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;
        bool apenasGerarIdeia = false;
        final TextEditingController observationController = TextEditingController();
        final stt.SpeechToText speechToText = stt.SpeechToText();
        bool isListening = false;
        String lastWords = "";

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final accountNames = _controller.accounts.map((a) => a.accountName).toList();
            
            List<String> dialogTemplateNames = ['Todos'];
            if (selectedEmpresa != null) {
              try {
                final company = _controller.accounts.firstWhere((a) => a.accountName == selectedEmpresa);
                final companyTemplates = _controller.allTemplates.where((t) => company.templateIds.contains(t.id)).toList();
                dialogTemplateNames.addAll(companyTemplates.map((t) => t.name));
              } catch (_) {
                dialogTemplateNames.addAll(_controller.allTemplates.map((t) => t.name));
              }
            } else {
              dialogTemplateNames.addAll(_controller.allTemplates.map((t) => t.name));
            }

            if (!dialogTemplateNames.contains(selectedTemplate)) {
              selectedTemplate = 'Todos';
            }

            return AlertDialog(
              title: const Text('Criar Novo Conteúdo'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  CustomDropdown(
                    label: 'Empresa',
                    hint: 'Selecionar Empresa',
                    value: selectedEmpresa,
                    items: accountNames,
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedEmpresa = value;
                          selectedTemplate = 'Todos';
                          selectedDate = _getSuggestedDateForTemplate(selectedTemplate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomDropdown(
                    label: 'Template de Conteúdo',
                    hint: 'Modelo',
                    value: selectedTemplate,
                    items: dialogTemplateNames,
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedTemplate = value;
                          selectedDate = _getSuggestedDateForTemplate(selectedTemplate);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
                        );
                        if (time != null && context.mounted) {
                          setStateDialog(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                          setState(() {
                            _lastSelectedTime = time;
                          });
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null
                                ? 'Selecionar Data e Hora'
                                : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year} às ${selectedDate!.hour.toString().padLeft(2, '0')}:${selectedDate!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: selectedDate == null ? AppColors.textLight : AppColors.textDark,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.calendar_today, color: AppColors.textLight, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Apenas gerar ideia', style: TextStyle(fontSize: 14)),
                    value: apenasGerarIdeia,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) {
                      if (val != null) {
                        setStateDialog(() {
                          apenasGerarIdeia = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: observationController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: const InputDecoration(
                            labelText: 'Observação para IA (Opcional)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening ? Colors.red.withOpacity(0.1) : AppColors.surface,
                        ),
                        child: IconButton(
                          icon: Icon(isListening ? Icons.mic : Icons.mic_none, color: isListening ? Colors.red : AppColors.terracotta),
                          onPressed: () async {
                            if (!isListening) {
                              bool available = await speechToText.initialize();
                              if (available) {
                                setStateDialog(() {
                                  isListening = true;
                                  lastWords = observationController.text;
                                });
                                speechToText.listen(
                                  onResult: (result) {
                                    setStateDialog(() {
                                      final newText = lastWords.isEmpty ? result.recognizedWords : '$lastWords ${result.recognizedWords}';
                                      observationController.text = newText;
                                      if (result.finalResult) {
                                        lastWords = newText;
                                        isListening = false;
                                      }
                                    });
                                  },
                                  localeId: 'pt_BR',
                                );
                              }
                            } else {
                              setStateDialog(() => isListening = false);
                              speechToText.stop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (selectedEmpresa == null || selectedTemplate == 'Todos' || selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione Empresa e Template para criar.'), backgroundColor: AppColors.terracotta),
                      );
                      return;
                    }

                    setStateDialog(() => isLoading = true);

                    try {
                      final company = _controller.accounts.firstWhere((a) => a.accountName == selectedEmpresa);
                      final template = _controller.allTemplates.firstWhere((t) => t.name == selectedTemplate);

                      final apiResponse = await _controller.criarConteudo(
                        company, 
                        template.id, 
                        selectedDate!, 
                        apenasGerarIdeia: apenasGerarIdeia,
                        observacaoDoUsuario: observationController.text,
                      );
                      if (apiResponse.success && mounted) {
                        Navigator.of(context).pop();
                        _controller.setCompany(company.accountName);
                        _controller.setTemplate(template.name);
                        _controller.setTabIndex(1); // Mudar para "Em Construção"
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Criação de conteúdo iniciada com sucesso!'), backgroundColor: Colors.green),
                        );
                      } else if (mounted) {
                        setStateDialog(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(apiResponse.message ?? 'Erro ao criar conteúdo.'), backgroundColor: Colors.red),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setStateDialog(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Criar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nina Labs'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.terracotta,
              ),
              child: Text(
                'Nina Labs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.business, color: AppColors.textDark),
              title: const Text('Empresa', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final companyName = _controller.selectedCompany;
                bool? result;
                if (companyName != null) {
                  try {
                    final company = _controller.accounts.firstWhere((a) => a.accountName == companyName);
                    result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmpresaFormPage(account: company)),
                    );
                  } catch (e) {
                    result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmpresaFormPage()),
                    );
                  }
                } else {
                  result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmpresaFormPage()),
                  );
                }
                
                if (result == true) {
                  _controller.loadData();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy, color: AppColors.textDark),
              title: const Text('Templates', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(context);
                final companyName = _controller.selectedCompany;
                AccountModel? company;
                if (companyName != null) {
                  try {
                    company = _controller.accounts.firstWhere((a) => a.accountName == companyName);
                  } catch (_) {}
                }
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TemplatesPage(account: company)),
                );
                
                if (result != null) {
                  await _controller.loadData();
                  if (result is String) {
                    _controller.setTemplate(result);
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_controller.isLoading)
            const LinearProgressIndicator(color: AppColors.terracotta),
          if (!_controller.isLoading && _controller.errorMessage == null)
            _buildFilters(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppColors.terracotta,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: AppColors.surface,
          elevation: 0,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    CupertinoIcons.hand_thumbsup,
                    color: _controller.currentTabIndex == 0 ? AppColors.terracotta : AppColors.textLight,
                    size: 24,
                  ),
                  onPressed: () => _controller.setTabIndex(0),
                ),
                const SizedBox(width: 48), // Espaço para o FAB
                IconButton(
                  icon: Icon(
                    CupertinoIcons.wrench,
                    color: _controller.currentTabIndex == 1 ? AppColors.terracotta : AppColors.textLight,
                    size: 24,
                  ),
                  onPressed: () => _controller.setTabIndex(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
    }
    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Erro: ${_controller.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    return _controller.currentTabIndex == 0 ? _buildFeedSection() : _buildPendingSection();
  }

  Widget _buildFilters() {
    final accountNames = _controller.accounts.map((a) => a.accountName).toList();
    final templateNames = ['Todos', ..._controller.templates.map((t) => t.name)];
    
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          CustomDropdown(
            label: 'Empresa',
            hint: 'Selecionar Empresa',
            value: _controller.selectedCompany,
            items: accountNames,
            onChanged: (value) {
              if (value != null) {
                _controller.setCompany(value);
              }
            },
          ),
          const SizedBox(height: 8),
          CustomDropdown(
            label: 'Template de Conteúdo',
            hint: 'Modelo',
            value: _controller.selectedTemplate,
            items: templateNames,
            onChanged: (value) {
              if (value != null) {
                _controller.setTemplate(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    final contents = _controller.pendingContents;
    
    if (contents.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo em construção.'));
    }

    return ListView.builder(
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final content = contents[index];
        return SocialPostCard(
          key: ValueKey(content.id),
          content: content,
          isInitiallyWaiting: _controller.pollingPostIds.contains(content.id),
          onPollingChanged: (isPolling) => _controller.setPolling(content.id, isPolling),
          onRefresh: () => _controller.updatePost(content.id),
          onDelete: () => _controller.deletarConteudo(content.id),
        );
      },
    );

  }

  Widget _buildFeedSection() {
    final contents = _controller.postedContents;

    if (contents.isEmpty) {
      return const Center(child: Text('Nenhum conteúdo finalizado.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
          if (_controller.hasMoreFeed) {
            _controller.loadMoreFeed();
          }
        }
        return false;
      },
      child: ListView.builder(
        itemCount: contents.length + (_controller.hasMoreFeed ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == contents.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
            );
          }
          return SocialPostCard(
            key: ValueKey(contents[index].id),
            content: contents[index],
            isInitiallyWaiting: _controller.pollingPostIds.contains(contents[index].id),
            onPollingChanged: (isPolling) => _controller.setPolling(contents[index].id, isPolling),
            onRefresh: () => _controller.updatePost(contents[index].id),
            onDelete: () => _controller.deletarConteudo(contents[index].id),
          );
        },
      ),
    );
  }
}
