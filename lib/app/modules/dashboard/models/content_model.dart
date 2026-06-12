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

class ContentModel {
  final int id;
  final String companyName;
  final String templateName;
  final String status;
  final String imageUrl;
  final String description;
  final String date;
  final DateTime createdAt;

  ContentModel({
    required this.id,
    required this.companyName,
    required this.templateName,
    required this.status,
    required this.imageUrl,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json, List<AccountModel> accounts) {
    // 1. Resolve Company Name (matching post's idInstagram to company's idInstagramLinked)
    String cName = 'Desconhecida';
    final postInstaList = json['idInstagram'] as List?;
    if (postInstaList != null && postInstaList.isNotEmpty) {
      final postInstaId = postInstaList.first['id'];
      try {
        final match = accounts.firstWhere((acc) => acc.idInstagramLinked == postInstaId);
        cName = match.accountName;
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
    final templateList = json['idConteudo'] ?? json['field_8298718'] as List?;
    if (templateList != null && templateList.isNotEmpty) {
      templateStr = templateList.first['value'] ?? templateStr;
    }

    // 6. Resolve Date (Para Em Construção)
    String dateStr = json['DataHoraUltimaSolicitacao'] ?? json['field_9017937'] ?? '';
    if (dateStr.isNotEmpty) {
      try {
        final d = DateTime.parse(dateStr).toLocal();
        final day = d.day.toString().padLeft(2, '0');
        final month = d.month.toString().padLeft(2, '0');
        final year = d.year.toString();
        final hour = d.hour.toString().padLeft(2, '0');
        final min = d.minute.toString().padLeft(2, '0');
        dateStr = '$day/$month/$year $hour:$min';
      } catch (_) {}
    }

    // 7. Resolve Created At para ordenação
    String rawDate = json['DataHora'] ?? json['field_6963661'] ?? '';
    DateTime parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    try {
      if (rawDate.isNotEmpty) {
        parsedDate = DateTime.parse(rawDate);
      }
    } catch (e) {
      // ignore
    }

    return ContentModel(
      id: json['id'] ?? 0,
      companyName: cName,
      templateName: templateStr,
      status: st,
      imageUrl: img,
      description: descText,
      date: dateStr,
      createdAt: parsedDate,
    );
  }
}
