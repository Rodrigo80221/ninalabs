import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/components/custom_dropdown.dart';
import '../../core/theme/app_colors.dart';
import 'controllers/dashboard_controller.dart';
import 'widgets/social_post_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController _controller = DashboardController();

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

  void _showCreatePostDialog() {
    String selectedEmpresa = _controller.selectedCompany ?? 'Todas';
    String selectedTemplate = _controller.selectedTemplate;
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final accountNames = ['Todas', ..._controller.accounts.map((a) => a.accountName)];
            
            List<String> dialogTemplateNames = ['Todos'];
            if (selectedEmpresa != 'Todas') {
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

            bool isLoading = false;

            return AlertDialog(
              title: const Text('Criar Novo Conteúdo'),
              content: Column(
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
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedDate == null 
                              ? 'Nenhuma data selecionada' 
                              : 'Agendado para: ${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year} ${selectedDate!.hour.toString().padLeft(2, '0')}:${selectedDate!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (date != null && context.mounted) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
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
                            }
                          }
                        },
                        child: const Text('Data e Hora', style: TextStyle(color: AppColors.terracotta)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (selectedEmpresa == 'Todas' || selectedTemplate == 'Todos' || selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecione Empresa, Template e Data/Hora para criar.'), backgroundColor: AppColors.terracotta),
                      );
                      return;
                    }

                    setStateDialog(() => isLoading = true);

                    try {
                      final company = _controller.accounts.firstWhere((a) => a.accountName == selectedEmpresa);
                      final template = _controller.allTemplates.firstWhere((t) => t.name == selectedTemplate);

                      final success = await _controller.criarConteudo(company, template.id, selectedDate!);
                      if (success && mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Criação de conteúdo iniciada com sucesso!'), backgroundColor: Colors.green),
                        );
                      } else if (mounted) {
                        setStateDialog(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erro ao criar conteúdo.'), backgroundColor: Colors.red),
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
                    CupertinoIcons.wrench,
                    color: _controller.currentTabIndex == 0 ? AppColors.terracotta : AppColors.textLight,
                    size: 24,
                  ),
                  onPressed: () => _controller.setTabIndex(0),
                ),
                const SizedBox(width: 48), // Espaço para o FAB
                IconButton(
                  icon: Icon(
                    CupertinoIcons.hand_thumbsup,
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
    return _controller.currentTabIndex == 0 ? _buildPendingSection() : _buildFeedSection();
  }

  Widget _buildFilters() {
    final accountNames = ['Todas', ..._controller.accounts.map((a) => a.accountName)];
    final templateNames = ['Todos', ..._controller.templates.map((t) => t.name)];
    
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          CustomDropdown(
            label: 'Empresa',
            hint: 'Selecionar Empresa',
            value: _controller.selectedCompany ?? 'Todas',
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
        return SocialPostCard(
          content: contents[index],
          onRefresh: () => _controller.updatePost(contents[index].id),
          onDelete: () => _controller.deletarConteudo(contents[index].id),
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
            content: contents[index],
            onRefresh: () => _controller.updatePost(contents[index].id),
            onDelete: () => _controller.deletarConteudo(contents[index].id),
          );
        },
      ),
    );
  }
}
