import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/baserow_service.dart';
import '../../core/theme/app_colors.dart';
import '../dashboard/models/content_model.dart';

class TemplateFormPage extends StatefulWidget {
  final TemplateModel? template;

  const TemplateFormPage({super.key, this.template});

  @override
  State<TemplateFormPage> createState() => _TemplateFormPageState();
}

class _TemplateFormPageState extends State<TemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final BaserowService _baserowService = BaserowService();
  bool _isLoading = false;

  Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameController.text = widget.template!.name;
      if (widget.template!.regras != null && widget.template!.regras!.isNotEmpty) {
        try {
          _formData = jsonDecode(widget.template!.regras!);
        } catch (e) {
          print('Erro ao carregar JSON das regras: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text;
      final regrasJson = const JsonEncoder.withIndent('  ').convert(_formData);

      if (widget.template == null) {
        await _baserowService.createTemplate(name: name, regras: regrasJson);
      } else {
        await _baserowService.updateTemplate(widget.template!.id, name: name, regras: regrasJson);
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

  // --- UI Helpers ---

  void _updateForm(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
  }

  String _getString(String key) => _formData[key]?.toString() ?? '';
  List<String> _getList(String key) => (_formData[key] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.terracotta),
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

  Widget _buildRadio(String title, String key, List<String> options) {
    final currentValue = _getString(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...options.map((o) => RadioListTile<String>(
                title: Text(o),
                value: o,
                groupValue: currentValue,
                onChanged: (val) => _updateForm(key, val),
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
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
              _buildRadio('Modo de geração das imagens', 'modoGeracaoImagens', [
                'Imagens distintas',
                'Imagem de referência (sequência)'
              ]),
              _buildDropdown('Quantidade Máxima de Imagens Geradas', 'qtdMaximaImagens', List.generate(30, (i) => (i + 1).toString())),
              _buildRadio('Tecnologias de geração de cada Imagem', 'tecnologiasImagens', [
                'Imagem 1 com Nano Banana 3 e as demais com Nano Banana 2.5',
                'Todas Imagens com Nano Banana 3',
                'Todas Imagens com Nano Banana 2.5',
                'Todas Imagens com Google Imagen',
                'Todas Imagens com HTML',
                'Vou enviar a imagem'
              ]),
              _buildRadio('Usa Imagem de um ator ou atriz de referência?', 'usoImagemReferencia', [
                'Apenas imagem de capa usa referência; demais não usam',
                'Todas as imagens usam referência',
                'Apenas imagens internas usam referência; capa não usa',
                'Nenhuma imagem usa referência'
              ]),
              _buildTextField('Código ou URL da imagem de referência (Se "Não", escreva "Não possui")', 'idImagemReferencia'),
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
              _buildYesNo('Utiliza narrador?', 'utilizaNarrador'),
              if (usaNarrador) _buildTextField('Voz do narrador (Ex: Leda, Masculino IA)', 'vozNarrador'),
              
              const Divider(height: 32),
              
              _buildYesNo('Inclui legenda?', 'incluiLegenda'),
              if (usaLegenda) ...[
                _buildYesNo('Inclui cor de legenda personalizada?', 'incluiCorLegendaPersonalizada'),
                _buildTextField('Configuração de legenda PT', 'configLegendaPT', maxLines: 4),
                _buildTextField('Configuração de legenda EN', 'configLegendaEN', maxLines: 4),
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
              _buildDropdown('Objetivo do Conteúdo', 'objetivoConteudo', [
                'Vender produto', 'Divulgar serviço', 'Ganhar seguidores', 'Engajar audiência',
                'Educar público', 'Fortalecer marca', 'Gerar leads', 'Gerar tráfego para site', 'Atrair seguidores'
              ]),
              _buildDropdown('Estilo do Conteúdo', 'estiloConteudo', [
                'Educacional', 'Entretenimento', 'Inspiracional', 'Autoridade', 'Storytelling'
              ]),
              _buildTextField('Tema, Tom da Comunicação e Emoção Principal (Resumo)', 'contextoGeral', maxLines: 3),
              _buildDropdown('Público-Alvo', 'publicoAlvo', [
                'Jovens (18–25)', 'Adultos (25–40)', 'Empresários', 'Profissionais liberais', 'Estudantes', 'Público geral'
              ]),
              _buildDropdown('Nível de Viralidade', 'nivelViralidade', [
                'Conteúdo seguro', 'Conteúdo forte', 'Conteúdo viral'
              ]),
              _buildDropdown('Idioma do Gancho', 'idiomaGancho', [
                'Português', 'Inglês', 'Espanhol', 'Português + Inglês (misturado)'
              ]),
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
              _buildTextField('Informações adicionais para orientar a IA', 'informacoesAdicionais', maxLines: 6),
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

                    const SizedBox(height: 32),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
                        child: const Text('Salvar Template', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
