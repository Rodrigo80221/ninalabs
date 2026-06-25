import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import '../../core/services/baserow_service.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/models/content_model.dart';
import '../dashboard/models/google_voice_model.dart';
import 'widgets/subtitle_config_widget.dart';
import 'package:just_audio/just_audio.dart';

class TemplateFormPage extends StatefulWidget {
  final TemplateModel? template;
  final AccountModel? account;

  const TemplateFormPage({super.key, this.template, this.account});

  @override
  State<TemplateFormPage> createState() => _TemplateFormPageState();
}

class _TemplateFormPageState extends State<TemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final BaserowService _baserowService = BaserowService();
  bool _isLoading = false;

  late QuillController _quillIdentidadeController;
  late QuillController _quillInformacoesController;
  final _identidadeFocusNode = FocusNode();
  final _informacoesFocusNode = FocusNode();

  QuillController _createQuillController(Document? doc, {TextSelection? selection}) {
    return QuillController(
      document: doc ?? Document(),
      selection: selection ?? const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          onClipboardPaste: () async {
            return true;
          },
        ),
      ),
    );
  }

  void _onPaste(ClipboardReadEvent event) async {
    final focusNode = _identidadeFocusNode.hasFocus ? _identidadeFocusNode : (_informacoesFocusNode.hasFocus ? _informacoesFocusNode : null);
    if (focusNode == null) return;
    final controller = _identidadeFocusNode.hasFocus ? _quillIdentidadeController : _quillInformacoesController;

    try {
      final reader = await event.getClipboardReader();
      if (reader.canProvide(Formats.htmlText)) {
        var html = await reader.readValue(Formats.htmlText);
        if (html != null && html.isNotEmpty) {
          html = html.replaceAll(RegExp(r'<b\s+[^>]*id="docs-internal-guid-[^>]+>'), '');
          if (html.endsWith('</b>')) {
            html = html.substring(0, html.length - 4);
          }
          final delta = HtmlToDelta().convert(html);
          final index = controller.selection.baseOffset;
          final length = controller.selection.extentOffset - index;
          controller.replaceText(index, length, delta, null);
        }
      } else if (reader.canProvide(Formats.plainText)) {
        final text = await reader.readValue(Formats.plainText);
        if (text != null && text.isNotEmpty) {
          final index = controller.selection.baseOffset;
          final length = controller.selection.extentOffset - index;
          controller.replaceText(index, length, text, null);
        }
      }
    } catch (e) {
      debugPrint("Erro ao colar: $e");
    }
  }

  int _versaoOriginal = 1;
  int _versaoAtual = 1;
  bool _versaoIncrementada = false;

  Map<String, dynamic> _formData = {};
  
  List<String> _musicOptions = [];
  String? _selectedMusicOption;
  
  List<GoogleVoiceModel> _dynamicGoogleVoices = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    ClipboardEvents.instance?.registerPasteEventListener(_onPaste);
    _quillIdentidadeController = _createQuillController(null);
    _quillInformacoesController = _createQuillController(null);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      _selectedMusicOption = widget.template!.usaMusicasDeFundoPreGravadas;
      _formData['identidade'] = widget.template!.identidade;
      
      if (widget.template!.identidade != null && widget.template!.identidade!.isNotEmpty) {
        try {
          final myJSON = jsonDecode(widget.template!.identidade!);
          _quillIdentidadeController = _createQuillController(Document.fromJson(myJSON));
        } catch (e) {
          _quillIdentidadeController = _createQuillController(null);
          _quillIdentidadeController.document.insert(0, widget.template!.identidade!);
        }
      }

      _versaoOriginal = widget.template!.versao;
      _versaoAtual = _versaoOriginal;
      if (widget.template!.regras != null && widget.template!.regras!.isNotEmpty) {
        try {
          _formData = jsonDecode(widget.template!.regras!);
          
          String infoStr = _formData['informacoesAdicionais']?.toString() ?? '';
          if (infoStr.isNotEmpty) {
            try {
              final myJSON = jsonDecode(infoStr);
              _quillInformacoesController = _createQuillController(Document.fromJson(myJSON));
            } catch (e) {
              _quillInformacoesController = _createQuillController(null);
              _quillInformacoesController.document.insert(0, infoStr);
            }
          }
          
          if (_formData['utilizaNarrador'] == 'Sim' && _formData.containsKey('vozNarrador')) {
            final voz = _formData['vozNarrador'].toString();
            if (voz.startsWith('ElevenLabs_')) {
              _formData['motorVoz'] = 'ElevenLabs';
              _formData['vozNarradorElevenLabs'] = voz.substring('ElevenLabs_'.length);
            } else {
              _formData['motorVoz'] = 'Google';
              _formData['vozNarradorGoogle'] = voz;
            }
          }
        } catch (e) {
          print('Erro ao carregar JSON das regras: $e');
        }
      }
    }
    
    await Future.wait([
      _loadMusicOptions(),
      _fetchGoogleVoices(),
    ]);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchGoogleVoices() async {
    try {
      final voices = await _baserowService.fetchGoogleVoices();
      if (mounted) {
        _dynamicGoogleVoices = voices;
        final voz = _formData['vozNarradorGoogle']?.toString() ?? '';
        if (voz.isNotEmpty && !voz.contains(' -- ')) {
          try {
            final fullVoice = _dynamicGoogleVoices.firstWhere((v) => v.name == voz);
            _formData['vozNarradorGoogle'] = '${fullVoice.name} -- ${fullVoice.style}';
          } catch (_) {
            if (_dynamicGoogleVoices.isNotEmpty) {
              _formData['vozNarradorGoogle'] = '${_dynamicGoogleVoices.first.name} -- ${_dynamicGoogleVoices.first.style}';
            }
          }
        } else if (voz.isEmpty && _dynamicGoogleVoices.isNotEmpty) {
          _formData['vozNarradorGoogle'] = '${_dynamicGoogleVoices.first.name} -- ${_dynamicGoogleVoices.first.style}';
        }
      }
    } catch (e) {
      print('Erro ao carregar Google Voices: $e');
    }
  }

  Future<void> _loadMusicOptions() async {
    try {
      final options = await _baserowService.fetchMusicOptions();
      if (mounted) {
        setState(() {
          _musicOptions = ['Nenhuma', ...options];
          if (_selectedMusicOption == null || !_musicOptions.contains(_selectedMusicOption)) {
            _selectedMusicOption = _musicOptions.first;
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar opções de música: $e');
    }
  }

  @override
  void dispose() {
    ClipboardEvents.instance?.unregisterPasteEventListener(_onPaste);
    _nameController.dispose();
    _audioPlayer.dispose();
    _quillIdentidadeController.dispose();
    _quillInformacoesController.dispose();
    _identidadeFocusNode.dispose();
    _informacoesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text;

      _formData['identidade'] = jsonEncode(_quillIdentidadeController.document.toDelta().toJson());
      _formData['informacoesAdicionais'] = jsonEncode(_quillInformacoesController.document.toDelta().toJson());

      final formDataToSave = Map<String, dynamic>.from(_formData);

      final tipoConteudo = _getString('tipoConteudo');
      final isVideo = tipoConteudo.toLowerCase().contains('vídeo') || tipoConteudo.toLowerCase().contains('video');

      if (!isVideo) {
        formDataToSave.remove('duracaoVideo');
        formDataToSave.remove('ritmoConteudo');
        formDataToSave.remove('criacaoBackgroundMusic');
        formDataToSave.remove('utilizaNarrador');
        formDataToSave.remove('motorVoz');
        formDataToSave.remove('vozNarradorGoogle');
        formDataToSave.remove('vozNarradorElevenLabs');
        formDataToSave.remove('vozNarrador');
        formDataToSave.remove('incluiLegenda');
        formDataToSave.remove('incluiCorLegendaPersonalizada');
        formDataToSave.remove('configLegendaPT');
        formDataToSave.remove('configLegendaEN');
        formDataToSave.remove('idiomaNarracao');
      } else {
        if (formDataToSave['utilizaNarrador'] != 'Sim') {
          formDataToSave.remove('motorVoz');
          formDataToSave.remove('vozNarradorGoogle');
          formDataToSave.remove('vozNarradorElevenLabs');
          formDataToSave.remove('vozNarrador');
        } else {
          final motorVoz = formDataToSave['motorVoz'];
          if (motorVoz == 'Google') {
            formDataToSave.remove('vozNarradorElevenLabs');
            final vozGoogle = formDataToSave['vozNarradorGoogle']?.toString() ?? '';
            if (vozGoogle.isNotEmpty) {
              formDataToSave['vozNarrador'] = vozGoogle.split(' -- ').first;
            }
          } else if (motorVoz == 'ElevenLabs') {
            formDataToSave.remove('vozNarradorGoogle');
            final vozElevenLabs = formDataToSave['vozNarradorElevenLabs']?.toString() ?? '';
            if (vozElevenLabs.isNotEmpty) {
              formDataToSave['vozNarrador'] = 'ElevenLabs_$vozElevenLabs';
            }
          }
        }

        if (formDataToSave['incluiLegenda'] != 'Sim') {
          formDataToSave.remove('incluiCorLegendaPersonalizada');
          formDataToSave.remove('configLegendaPT');
          formDataToSave.remove('configLegendaEN');
        }
      }

      if (formDataToSave['usoImagemReferencia'] == 'Nenhuma imagem usa referência') {
        formDataToSave.remove('idImagemReferencia');
        formDataToSave.remove('identidade');
      }

      final identidadeValue = formDataToSave.remove('identidade');

      final regrasJson = const JsonEncoder.withIndent('  ').convert(formDataToSave);

      final isCriacaoBgMusic = _getString('criacaoBackgroundMusic') == 'Sim';
      String? finalMusicOption = _selectedMusicOption;

      if (!isVideo || isCriacaoBgMusic || finalMusicOption == 'Nenhuma') {
        finalMusicOption = null;
      }

      if (widget.template == null) {
        final newId = await _baserowService.createTemplate(
          name: name,
          regras: regrasJson,
          accountId: widget.account?.id,
          idInstagramLinked: widget.account?.idInstagramLinked,
          usaMusicasDeFundoPreGravadas: finalMusicOption,
          identidade: identidadeValue?.toString(),
          versao: _versaoAtual,
        );
        if (widget.account != null) {
          widget.account!.templateIds.add(newId);
        }
      } else {
        await _baserowService.updateTemplate(
          widget.template!.id,
          name: name,
          regras: regrasJson,
          usaMusicasDeFundoPreGravadas: finalMusicOption,
          identidade: identidadeValue?.toString(),
          versao: _versaoAtual,
        );
      }

      if (mounted) {
        Navigator.pop(context, name);
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

  // --- UI Helpers ---

  Widget _buildQuillEditor(String title, QuillController controller, FocusNode focusNode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () => _showFullScreenEditor(title, controller, focusNode),
                tooltip: 'Maximizar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          QuillSimpleToolbar(
            controller: controller,
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
          Container(
            height: 200,
            margin: const EdgeInsets.only(top: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: QuillEditor.basic(
              controller: controller,
              focusNode: focusNode,
              config: const QuillEditorConfig(
                padding: EdgeInsets.all(16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenEditor(String title, QuillController controller, FocusNode focusNode) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen_exit),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Column(
            children: [
              QuillSimpleToolbar(
                controller: controller,
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
                    controller: controller,
                    focusNode: focusNode,
                    config: const QuillEditorConfig(
                      padding: EdgeInsets.all(16.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      fullscreenDialog: true,
    ));
  }

  void _updateForm(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
  }

  String _getString(String key) => _formData[key]?.toString() ?? '';
  List<String> _getList(String key) {
    final value = _formData[key];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.terracotta),
      ),
    );
  }

  Widget _buildGoogleVoicesSection() {
    if (_dynamicGoogleVoices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: Text('Carregando vozes...', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    final currentValue = _getString('vozNarradorGoogle');
    final options = _dynamicGoogleVoices.map((v) => '${v.name} -- ${v.style}').toList();
    final value = options.contains(currentValue) ? currentValue : options.first;
    
    GoogleVoiceModel? selectedModel;
    try {
      selectedModel = _dynamicGoogleVoices.firstWhere((v) => '${v.name} -- ${v.style}' == value);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Voz (Google)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, fillColor: Colors.white, filled: true),
                  value: value,
                  items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (val) {
                    if (val != null) _updateForm('vozNarradorGoogle', val);
                  },
                ),
              ),
            ],
          ),
          if (selectedModel != null && (selectedModel.audioUrl != null || selectedModel.audioEnglishUrl != null)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (selectedModel.audioUrl != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _audioPlayer.stop();
                        final latestModel = await _baserowService.fetchGoogleVoice(selectedModel!.id);
                        if (latestModel.audioUrl != null) {
                          await _audioPlayer.setUrl(latestModel.audioUrl!);
                          _audioPlayer.play();
                        }
                      } catch (e) {
                        print('Erro ao tocar áudio PT: $e');
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Ouvir PT'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                if (selectedModel.audioUrl != null && selectedModel.audioEnglishUrl != null)
                  const SizedBox(width: 8),
                if (selectedModel.audioEnglishUrl != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _audioPlayer.stop();
                        final latestModel = await _baserowService.fetchGoogleVoice(selectedModel!.id);
                        if (latestModel.audioEnglishUrl != null) {
                          await _audioPlayer.setUrl(latestModel.audioEnglishUrl!);
                          _audioPlayer.play();
                        }
                      } catch (e) {
                        print('Erro ao tocar áudio EN: $e');
                      }
                    },
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Ouvir EN'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDropdown(String title, String key, List<String> options) {
    final currentValue = _getString(key);
    final value = options.contains(currentValue) ? currentValue : null;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, fillColor: Colors.white, filled: true),
            value: value,
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (val) => _updateForm(key, val),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(String title, String key, List<String> options, {List<String> disabledOptions = const []}) {
    final currentValue = _getString(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...options.map((o) {
            final isDisabled = disabledOptions.contains(o);
            return RadioListTile<String>(
              title: Text(o, style: isDisabled ? const TextStyle(color: Colors.grey) : null),
              value: o,
              groupValue: currentValue,
              onChanged: isDisabled ? null : (val) => _updateForm(key, val),
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildYesNo(String title, String key) {
    return _buildRadio(title, key, ['Sim', 'Não']);
  }

  Widget _buildTextField(String title, String key, {int maxLines = 1}) {
    final initialValue = _getString(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: initialValue,
            maxLines: maxLines,
            decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true),
            onChanged: (val) => _updateForm(key, val),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxList(String title, String key, List<String> options) {
    final currentList = _getList(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...options.map((o) {
            return CheckboxListTile(
              title: Text(o),
              value: currentList.contains(o),
              onChanged: (checked) {
                final List<String> newList = List.from(currentList);
                if (checked == true) {
                  newList.add(o);
                } else {
                  newList.remove(o);
                }
                _updateForm(key, newList);
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String title, String key) {
    final currentValue = _getString(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final initialTime = TimeOfDay.now();
              final time = await showTimePicker(
                context: context,
                initialTime: initialTime,
              );
              if (time != null) {
                final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                _updateForm(key, formatted);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(border: OutlineInputBorder(), fillColor: Colors.white, filled: true, isDense: true),
              child: Text(currentValue.isEmpty ? 'Selecione o horário' : currentValue),
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTIONS ---

  List<Widget> _buildParte1() {
    final tipoConteudo = _getString('tipoConteudo');
    final isVideo = tipoConteudo.toLowerCase().contains('vídeo') || tipoConteudo.toLowerCase().contains('video');

    return [
      _buildSectionHeader('PARTE 1 — CONFIGURAÇÃO TÉCNICA DE MÍDIA'),
      Card(
        color: AppColors.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckboxList('Plataforma de Publicação', 'plataformas', [
                'Instagram', 'LinkedIn'
              ]),
              _buildRadio('Formato de Conteúdo', 'formatoConteudo', ['Série recorrente', 'Conteúdo isolado']),
              _buildRadio('Proporção da Mídia', 'proporcaoMedia', ['9:16 (Vertical)', '4:5 (Retrato)', '1:1 (Quadrado)', '16:9 (Horizontal)']),
              _buildRadio('Tipo de Conteúdo', 'tipoConteudo', ['Vídeo curto', 'Vídeo longo', 'Imagem única', 'Carrossel de imagens']),
              
              if (isVideo) ...[
                _buildRadio('Duração do Vídeo', 'duracaoVideo', ['5–10 segundos', '10–20 segundos', '20–40 segundos', '40–60 segundos', 'Mais de 1 minuto']),
                _buildRadio('Ritmo do Conteúdo', 'ritmoConteudo', [
                  'Muito rápido (conteúdo extremamente dinâmico)',
                  'Rápido (cortes frequentes e fala direta)',
                  'Normal (explicação equilibrada)',
                  'Storytelling (narrativa mais lenta e envolvente)'
                ]),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildGeracaoImagens() {
    return [
      _buildSectionHeader('GERAÇÃO DE IMAGENS'),
      Card(
        color: AppColors.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRadio(
                'Modo de geração das imagens',
                'modoGeracaoImagens',
                [
                  'Imagens distintas',
                  'Imagem de Referência (New Text Advertisement — Under Development)'
                ],
                disabledOptions: ['Imagem de Referência (New Text Advertisement — Under Development)'],
              ),
              _buildDropdown('Quantidade Máxima de Imagens Geradas', 'qtdMaximaImagens', List.generate(30, (i) => (i + 1).toString())),
              _buildRadio(
                'Tecnologias de geração de cada Imagem',
                'tecnologiasImagens',
                [
                  'Imagem 1 com Nano Banana 3 e as demais com Nano Banana 2.5',
                  'Todas Imagens com Nano Banana 3',
                  'Todas Imagens com Nano Banana 2.5',
                  'Todas Imagens com Google Imagen',
                  'Todas Imagens com HTML',
                  'Vou enviar a imagem (em desenvolvimento)'
                ],
                disabledOptions: ['Vou enviar a imagem (em desenvolvimento)'],
              ),
              _buildRadio(
                'Usa Imagem de um ator ou atriz de referência?',
                'usoImagemReferencia',
                [
                  'Apenas imagem de capa usa referência; demais não usam',
                  'Todas as imagens usam referência',
                  'Nenhuma imagem usa referência'
                ],
              ),
              if (_getString('usoImagemReferencia') != 'Nenhuma imagem usa referência') ...[
                _buildTextField('Código ou URL da imagem de referência', 'idImagemReferencia'),
                _buildQuillEditor('Descrição de Perfil (Características do ator/atriz)', _quillIdentidadeController, _identidadeFocusNode),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildAudioELegendas() {
    final tipoConteudo = _getString('tipoConteudo');
    final isVideo = tipoConteudo.toLowerCase().contains('vídeo') || tipoConteudo.toLowerCase().contains('video');

    if (!isVideo) return []; // Ocultar para Imagens

    final usaNarrador = _getString('utilizaNarrador') == 'Sim';
    final usaLegenda = _getString('incluiLegenda') == 'Sim';
    final isCriacaoBgMusic = _getString('criacaoBackgroundMusic') == 'Sim';

    return [
      _buildSectionHeader('ÁUDIO E NARRAÇÃO / LEGENDAS'),
      Card(
        color: AppColors.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYesNo('Criação de background music?', 'criacaoBackgroundMusic'),
              
              if (_getString('criacaoBackgroundMusic') == 'Não')
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Usa Músicas de Fundo Pré Gravadas?', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMusicOption,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                          isDense: true,
                        ),
                        hint: const Text('Selecione uma opção'),
                        items: _musicOptions.map((String option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedMusicOption = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              
              _buildYesNo('Utiliza narrador?', 'utilizaNarrador'),
              if (usaNarrador) ...[
                _buildRadio('Motor de voz', 'motorVoz', ['Google', 'ElevenLabs']),
                if (_getString('motorVoz') == 'Google')
                  _buildGoogleVoicesSection(),
                if (_getString('motorVoz') == 'ElevenLabs')
                  _buildTextField('Código da voz (ElevenLabs)', 'vozNarradorElevenLabs'),
              ],
              
              const Divider(height: 32),
              
              _buildYesNo('Inclui legenda?', 'incluiLegenda'),
              if (usaLegenda) ...[
                _buildYesNo('Inclui cor de legenda personalizada?', 'incluiCorLegendaPersonalizada'),
                if (_getString('incluiCorLegendaPersonalizada') == 'Sim') ...[
                  SubtitleConfigWidget(
                    title: 'Configuração de legenda PT',
                    initialValue: _getString('configLegendaPT'),
                    onChanged: (val) => _updateForm('configLegendaPT', val),
                  ),
                  SubtitleConfigWidget(
                    title: 'Configuração de legenda EN',
                    initialValue: _getString('configLegendaEN'),
                    onChanged: (val) => _updateForm('configLegendaEN', val),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildConfigInstagram() {
    return [
      _buildSectionHeader('CONFIGURAÇÃO INSTAGRAM'),
      Card(
        color: AppColors.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYesNo('Agendar Postagem do Conteúdo no Instagram?', 'agendarPostagem'),
              _buildYesNo('Deve responder comentários automaticamente?', 'responderComentarios'),
              _buildYesNo('Deve responder DM automaticamente?', 'responderDM'),
              _buildRadio('Onde Publicar', 'ondePublicar', ['Feed', 'Stories']),
              _buildRadio('Tipo de mídia', 'tipoMedia', ['imagem', 'carrossel', 'vídeo']),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildParte2() {
    final tipoConteudo = _getString('tipoConteudo');
    final isVideo = tipoConteudo.toLowerCase().contains('vídeo') || tipoConteudo.toLowerCase().contains('video');

    return [
      _buildSectionHeader('PARTE 2 — ESTRATÉGIA DE CONTEÚDO'),
      Card(
        color: AppColors.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildYesNo('Utiliza pesquisa de tendências e conteúdo na web?', 'utilizaPesquisa'),
              _buildCheckboxList('Objetivo do Conteúdo', 'objetivoConteudo', [
                'Vender produto', 'Divulgar serviço', 'Engajar audiência',
                'Educar público', 'Fortalecer marca', 'Gerar leads', 'Gerar tráfego para site', 'Atrair seguidores'
              ]),
              _buildDropdown('Estilo do Conteúdo', 'estiloConteudo', [
                'Educacional', 'Entretenimento', 'Inspiracional', 'Autoridade', 'Storytelling'
              ]),
              _buildDropdown('Público-Alvo', 'publicoAlvo', [
                'Jovens (18–25)', 'Adultos (25–40)', 'Empresários', 'Profissionais liberais', 'Estudantes', 'Público geral'
              ]),
              _buildDropdown('Nível de Viralidade', 'nivelViralidade', [
                'Conteúdo seguro', 'Conteúdo forte', 'Conteúdo viral'
              ]),
              _buildDropdown('Idioma do Gancho', 'idiomaGancho', [
                'Português', 'Inglês', 'Espanhol', 'Português + Inglês (misturado)'
              ]),
              if (isVideo)
                _buildDropdown('Idioma da Narração', 'idiomaNarracao', [
                  'Português', 'Inglês', 'Espanhol', 'Português + Inglês (misturado)'
                ]),
              _buildDropdown('Profundidade do Conteúdo', 'profundidadeConteudo', [
                'Superficial', 'Intermediário', 'Profundo'
              ]),
              _buildDropdown('Estrutura do Script', 'estruturaScript', [
                'Gancho → Valor → Exemplo → CTA', 'Gancho → Problema → Solução → CTA', 'Gancho → História → Insight → CTA'
              ]),
              _buildDropdown('Estilo de Gancho', 'estiloGancho', [
                'Curiosidade', 'Erro comum', 'Pergunta provocativa', 'Dica rápida', 'Alerta',
                'Curiosidade local', 'Contradição', 'Estatística surpreendente'
              ]),
              _buildDropdown('Chamada para Ação (CTA)', 'chamadaAcao', [
                'Seguir o perfil', 'Curtir o post', 'Comentar', 'Compartilhar', 'Acessar link na bio',
                'Entrar em contato no WhatsApp', 'Comprar produto'
              ]),
              _buildDropdown('Nível de criatividade permitido para a IA', 'nivelCriatividade', [
                'Baixo', 'Médio', 'Alto', 'Muito alto'
              ]),
              _buildQuillEditor('Informações adicionais para orientar a IA', _quillInformacoesController, _informacoesFocusNode),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildProgramacao() {
    return [
      _buildSectionHeader('SESSÃO PROGRAMAÇÃO DE POSTAGEM'),
      Card(
        color: AppColors.surface,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheckboxList('Dias de Publicação', 'diasPublicacao', [
                'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
              ]),
              _buildTimePicker('Horário de Publicação', 'horarioPublicacao'),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'Novo Template' : 'Editar Template'),
      ),
      bottomNavigationBar: _getString('tipoConteudo').isNotEmpty && !_isLoading
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
                    child: const Text('Salvar Template', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Template',
                      border: OutlineInputBorder(),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o nome do template';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  ..._buildParte1(),
                  
                  if (_getString('tipoConteudo').isNotEmpty) ...[
                    ..._buildGeracaoImagens(),
                    ..._buildAudioELegendas(),
                    ..._buildConfigInstagram(),
                    ..._buildParte2(),
                    ..._buildProgramacao(),

                    const SizedBox(height: 16),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Versão atual: $_versaoAtual', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark)),
                        if (!_versaoIncrementada && widget.template != null)
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _versaoAtual++;
                                _versaoIncrementada = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: AppColors.terracotta, elevation: 1),
                            child: const Text('Nova Versão'),
                          ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}
