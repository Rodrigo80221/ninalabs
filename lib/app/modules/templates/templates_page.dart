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
