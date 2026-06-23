import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import '../../core/services/baserow_service.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/models/content_model.dart';

class EmpresaFormPage extends StatefulWidget {
  final AccountModel? account;
  
  const EmpresaFormPage({super.key, this.account});

  @override
  State<EmpresaFormPage> createState() => _EmpresaFormPageState();
}

class _EmpresaFormPageState extends State<EmpresaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late QuillController _quillController;
  final BaserowService _baserowService = BaserowService();
  bool _isLoading = false;
  
  final _editorFocusNode = FocusNode();

  QuillController _createQuillController(Document? doc, {TextSelection? selection}) {
    return QuillController(
      document: doc ?? Document(),
      selection: selection ?? const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          onClipboardPaste: () async {
            // Prevent Quill's default paste so our global ClipboardEvents listener handles it
            return true;
          },
        ),
      ),
    );
  }

  void _onPaste(ClipboardReadEvent event) async {
    debugPrint("Intercepted Paste Event!");
    if (!_editorFocusNode.hasFocus) {
      debugPrint("Editor does not have focus. Ignoring paste.");
      return;
    }

    try {
      final reader = await event.getClipboardReader();
      debugPrint("Available formats: \${reader.platformFormats}");
      if (reader.canProvide(Formats.htmlText)) {
        debugPrint("Clipboard has HTML!");
        var html = await reader.readValue(Formats.htmlText);
        debugPrint("HTML content length: \${html?.length}");
        if (html != null && html.isNotEmpty) {
          // Remove Google Docs wrapper that causes block elements to be stripped
          html = html.replaceAll(RegExp(r'<b\s+[^>]*id="docs-internal-guid-[^>]+>'), '');
          if (html.endsWith('</b>')) {
            html = html.substring(0, html.length - 4);
          }
          final delta = HtmlToDelta().convert(html);
          debugPrint("Converted Delta: \$delta");
          final index = _quillController.selection.baseOffset;
          final length = _quillController.selection.extentOffset - index;
          _quillController.replaceText(index, length, delta, null);
          debugPrint("Paste completed.");
        }
      } else if (reader.canProvide(Formats.plainText)) {
        debugPrint("Clipboard only has plain text.");
        final text = await reader.readValue(Formats.plainText);
        if (text != null && text.isNotEmpty) {
          final index = _quillController.selection.baseOffset;
          final length = _quillController.selection.extentOffset - index;
          _quillController.replaceText(index, length, text, null);
        }
      }
    } catch (e) {
      debugPrint("Erro ao colar: \$e");
    }
  }

  @override
  void initState() {
    super.initState();
    ClipboardEvents.instance?.registerPasteEventListener(_onPaste);
    
    if (widget.account != null) {
      _nameController.text = widget.account!.accountName;
      
      if (widget.account!.informacoesDaEmpresa != null && widget.account!.informacoesDaEmpresa!.isNotEmpty) {
        try {
          final myJSON = jsonDecode(widget.account!.informacoesDaEmpresa!);
          _quillController = _createQuillController(Document.fromJson(myJSON));
        } catch (e) {
          // Fallback if it's plain text in Baserow
          _quillController = _createQuillController(null);
          _quillController.document.insert(0, widget.account!.informacoesDaEmpresa!);
        }
      } else {
        _quillController = _createQuillController(null);
      }
    } else {
      _quillController = _createQuillController(null);
    }
  }

  @override
  void dispose() {
    ClipboardEvents.instance?.unregisterPasteEventListener(_onPaste);
    _nameController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final name = _nameController.text;
      final informacoes = jsonEncode(_quillController.document.toDelta().toJson());

      if (widget.account == null) {
        await _baserowService.createAccount(name: name, informacoes: informacoes);
      } else {
        await _baserowService.updateAccount(widget.account!.id, name: name, informacoes: informacoes);
      }

      if (mounted) {
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? 'Nova Empresa' : 'Editar Empresa'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
        : Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Empresa',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome da empresa';
                      }
                      return null;
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Informações da Empresa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                QuillSimpleToolbar(
                  controller: _quillController,
                  config: const QuillSimpleToolbarConfig(
                    showFontFamily: false,
                    showFontSize: false,
                    showAlignmentButtons: true,
                    showBackgroundColorButton: false,
                    showColorButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QuillEditor.basic(
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      config: const QuillEditorConfig(
                        padding: EdgeInsets.all(16.0),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                      ),
                      child: const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
