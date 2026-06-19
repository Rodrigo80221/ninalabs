class AccountModel {
  final int id;
  final String accountName;
  final List<int> templateIds;
  final int? idInstagramLinked;

  AccountModel({
    required this.id,
    required this.accountName,
    required this.templateIds,
    this.idInstagramLinked,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final linkedTemplates = json['EmpresasContratos'] as List?;
    List<int> tIds = [];
    if (linkedTemplates != null) {
      tIds = linkedTemplates.map((t) => t['id'] as int).toList();
    }

    final linkedInsta = json['IdInstagram'] as List?;
    int? instaId;
    if (linkedInsta != null && linkedInsta.isNotEmpty) {
      instaId = linkedInsta.first['id'] as int;
    }

    return AccountModel(
      id: json['id'] ?? 0,
      accountName: json['Name'] ?? json['field_7048152'] ?? 'Empresa Desconhecida',
      templateIds: tIds,
      idInstagramLinked: instaId,
    );
  }
}

class TemplateModel {
  final int id;
  final String name;

  TemplateModel({required this.id, required this.name});

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] ?? 0,
      name: json['Name'] ?? json['field_7441612'] ?? 'Template Desconhecido',
    );
  }
}

class ContentProductionStep {
  final String title;
  final bool isCompleted;

  ContentProductionStep({required this.title, required this.isCompleted});
}

class ContentModel {
  final int id;
  final String companyName;
  final String templateName;
  final String status;
  final String imageUrl;
  final String description;
  final String date;
  final DateTime createdAt;
  final int companyId;
  final int templateId;
  final List<ContentProductionStep> productionSteps;

  ContentModel({
    required this.id,
    required this.companyName,
    required this.templateName,
    required this.status,
    required this.imageUrl,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.companyId,
    required this.templateId,
    required this.productionSteps,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json, List<AccountModel> accounts) {
    // 1. Resolve Company Name (matching post's idInstagram to company's idInstagramLinked)
    String cName = 'Desconhecida';
    int cId = 0;
    final postInstaList = json['idInstagram'] as List?;
    if (postInstaList != null && postInstaList.isNotEmpty) {
      final postInstaId = postInstaList.first['id'];
      try {
        final match = accounts.firstWhere((acc) => acc.idInstagramLinked == postInstaId);
        cName = match.accountName;
        cId = match.id;
      } catch (e) {
        cName = 'ID $postInstaId';
      }
    }

    // 2. Resolve Status
    final idPostagem = json['idPostagemInstagram'] ?? json['field_7028349'];
    String st = (idPostagem != null && idPostagem.toString().trim().isNotEmpty) ? 'Postado' : 'Pendente';

    // 3. Resolve Image URL
    String img = 'https://via.placeholder.com/400x300/F4DCD6/2C2C2C?text=Sem+Imagem';
    final openingImage = json['ImagemDeAbertura'] ?? json['field_6964823'] as List?;
    if (openingImage != null && openingImage.isNotEmpty) {
      img = openingImage.first['url'] ?? img;
    }

    // 4. Resolve Description (Full DescricaoPost)
    String descText = json['DescricaoPost'] ?? json['field_7012244'] ?? '';

    // 5. Resolve Template
    String templateStr = 'Template Desconhecido';
    int tId = 0;
    final templateList = json['idConteudo'] ?? json['field_8298718'] as List?;
    if (templateList != null && templateList.isNotEmpty) {
      templateStr = templateList.first['value'] ?? templateStr;
      tId = templateList.first['id'] as int? ?? 0;
    }

    // 6 & 7. Resolve Date (Para Em Construção) e Created At para ordenação
    String rawDate = json['DataHora'] ?? json['field_6963661'] ?? '';
    String dateStr = rawDate;
    DateTime parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      if (rawDate.isNotEmpty) {
        parsedDate = DateTime.parse(rawDate);
        final d = parsedDate.toLocal();
        final day = d.day.toString().padLeft(2, '0');
        final month = d.month.toString().padLeft(2, '0');
        final year = d.year.toString();
        final hour = d.hour.toString().padLeft(2, '0');
        final min = d.minute.toString().padLeft(2, '0');
        dateStr = '$day/$month/$year $hour:$min';
      }
    } catch (e) {
      // ignore
    }

    bool isFilled(String fieldId) {
      final val = json['field_$fieldId'] ?? json[fieldId];
      if (val == null) return false;
      if (val is String) return val.trim().isNotEmpty;
      if (val is List) return val.isNotEmpty;
      return true; // numbers, booleans, etc
    }

    final steps = [
      ContentProductionStep(
        title: 'Secretaria',
        isCompleted: isFilled('7403505') || isFilled('SecretariaJoyce'),
      ),
      ContentProductionStep(
        title: 'Estratégia',
        isCompleted: isFilled('6993999') || isFilled('EstrategistaDeConteudo'),
      ),
      ContentProductionStep(
        title: 'Planejamento',
        isCompleted: isFilled('6963717') || isFilled('Gestor'),
      ),
      ContentProductionStep(
        title: 'Conteúdo',
        isCompleted: isFilled('6963716') || isFilled('DiretorConteudo'),
      ),
      ContentProductionStep(
        title: 'HTML das imagens',
        isCompleted: isFilled('7441568') || isFilled('html2image'),
      ),
      ContentProductionStep(
        title: 'Imagem abertura',
        isCompleted: isFilled('6964823') || isFilled('ImagemDeAbertura'),
      ),
      ContentProductionStep(
        title: 'Imagens restantes',
        isCompleted: isFilled('6966274') || isFilled('ImagensRestantes'),
      ),
      ContentProductionStep(
        title: 'Narração',
        isCompleted: (isFilled('6975911') || isFilled('Narracao')) &&
                     (isFilled('6975912') || isFilled('AudioNarracao')),
      ),
      ContentProductionStep(
        title: 'Legenda',
        isCompleted: (isFilled('7004890') || isFilled('ArquivoLegenda')) ||
                     (isFilled('7133863') || isFilled('ArquivoLegendaOriginal')),
      ),
      ContentProductionStep(
        title: 'Vídeo base',
        isCompleted: (isFilled('6969404') || isFilled('VideoMaker')) &&
                     (isFilled('6970011') || isFilled('VideoEditado')),
      ),
      ContentProductionStep(
        title: 'Música de fundo',
        isCompleted: isFilled('6975660') || isFilled('BackgroundMusic'),
      ),
      ContentProductionStep(
        title: 'Vídeo c/ áudio',
        isCompleted: isFilled('7006491') || isFilled('VideoComAudio'),
      ),
      ContentProductionStep(
        title: 'Vídeo legendado',
        isCompleted: isFilled('7007172') || isFilled('VideoComLegendaPT'),
      ),
      ContentProductionStep(
        title: 'Descrição',
        isCompleted: isFilled('7012244') || isFilled('DescricaoPost'),
      ),
      ContentProductionStep(
        title: 'Agendamento',
        isCompleted: isFilled('7028349') || isFilled('idPostagemInstagram'),
      ),
    ];

    return ContentModel(
      id: json['id'] ?? 0,
      companyName: cName,
      templateName: templateStr,
      status: st,
      imageUrl: img,
      description: descText,
      date: dateStr,
      createdAt: parsedDate,
      companyId: cId,
      templateId: tId,
      productionSteps: steps,
    );
  }
}
