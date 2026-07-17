import 'package:flutter/material.dart';
import '../../core/services/baserow_service.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/models/content_model.dart';
import 'template_form_page.dart';

class TemplatesPage extends StatefulWidget {
  final AccountModel? account;
  const TemplatesPage({super.key, this.account});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final BaserowService _baserowService = BaserowService();
  List<TemplateModel> _templates = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastSavedTemplateName;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final templates = await _baserowService.fetchTemplates();
      setState(() {
        if (widget.account != null) {
          _templates = templates.where((t) => widget.account!.templateIds.contains(t.id)).toList();
        } else {
          _templates = templates;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _duplicateTemplate(TemplateModel template) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newName = '${template.name} (Cópia)';
      final newId = await _baserowService.createTemplate(
        name: newName,
        regras: template.regras ?? '{}',
        accountId: widget.account?.id,
        idInstagramLinked: widget.account?.idInstagramLinked,
        usaMusicasDeFundoPreGravadas: template.usaMusicasDeFundoPreGravadas,
        identidade: template.identidade,
        versao: 1,
      );

      if (widget.account != null) {
        widget.account!.templateIds.add(newId);
      }

      _dataChanged = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template "$newName" duplicado com sucesso!'), backgroundColor: Colors.green),
        );
      }
      await _loadTemplates();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao duplicar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTemplate(TemplateModel template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Template'),
          content: Text('Deseja mesmo excluir o template "${template.name}"?\n\nEsta ação é irreversível.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _baserowService.deleteTemplate(template.id);
      
      if (widget.account != null) {
        widget.account!.templateIds.remove(template.id);
      }

      _dataChanged = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template excluído com sucesso!'), backgroundColor: Colors.green),
        );
      }
      await _loadTemplates();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_lastSavedTemplateName ?? (_dataChanged ? true : null));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Templates'),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplateFormPage(account: widget.account),
              ),
            );
            if (result != null) {
              if (result is String) _lastSavedTemplateName = result;
              _dataChanged = true;
              _loadTemplates();
            }
          },
          backgroundColor: AppColors.terracotta,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erro: $_errorMessage', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTemplates,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_templates.isEmpty) {
      return const Center(child: Text('Nenhum template encontrado.'));
    }

    return ListView.builder(
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.terracotta,
            child: Icon(Icons.file_copy, color: Colors.white),
          ),
          title: Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.terracotta),
            onSelected: (value) {
              if (value == 'duplicate') {
                _duplicateTemplate(template);
              } else if (value == 'delete') {
                _deleteTemplate(template);
              } else if (value == 'plan') {
                // Planejamento de Conteúdo - não faz nada por enquanto
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, color: AppColors.terracotta, size: 20),
                    SizedBox(width: 8),
                    Text('Duplicar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'plan',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: AppColors.terracotta, size: 20),
                    SizedBox(width: 8),
                    Text('Planejamento de Conteúdo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TemplateFormPage(template: template, account: widget.account),
              ),
            );
            if (result != null) {
              if (result is String) _lastSavedTemplateName = result;
              _dataChanged = true;
              _loadTemplates();
            }
          },
        );
      },
    );
  }
}
