import 'schedule_model.dart';

class AccountModel {
  final int id;
  final String accountName;
  final List<int> templateIds;
  final int? idInstagramLinked;
  final String? informacoesDaEmpresa;

  AccountModel({
    required this.id,
    required this.accountName,
    required this.templateIds,
    this.idInstagramLinked,
    this.informacoesDaEmpresa,
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
      informacoesDaEmpresa: json['InformacoesDaEmpresa'] as String?,
    );
  }
}

class TemplateModel {
  final int id;
  final String name;
  final String? regras;
  final String? usaMusicasDeFundoPreGravadas;
  final String? identidade;
  final int versao;

  TemplateModel({
    required this.id,
    required this.name,
    this.regras,
    this.usaMusicasDeFundoPreGravadas,
    this.identidade,
    this.versao = 1,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    int v = 1;
    final rawVersao = json['Versao'] ?? json['field_7981691'];
    if (rawVersao is int) v = rawVersao;
    else if (rawVersao is double) v = rawVersao.toInt();
    else if (rawVersao is String) v = int.tryParse(rawVersao) ?? 1;

    return TemplateModel(
      id: json['id'] ?? 0,
      name: json['Name'] ?? json['field_7441612'] ?? 'Template Desconhecido',
      regras: json['Regras'] ?? json['field_9175683'],
      usaMusicasDeFundoPreGravadas: json['UsaMusicasDeFundoPreGravadas'] ?? json['field_8071084'],
      identidade: json['Identidade'] ?? json['field_9175684'],
      versao: v,
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
  String status;
  final String imageUrl;
  final String? videoUrl;
  final String description;
  final String date;
  String? postDate;
  final DateTime createdAt;
  final int companyId;
  final int templateId;
  final List<ContentProductionStep> productionSteps;
  int? linkedScheduleId;
  bool hasError;

  ContentModel({
    required this.id,
    required this.companyName,
    required this.templateName,
    required this.status,
    required this.imageUrl,
    this.videoUrl,
    required this.description,
    required this.date,
    this.postDate,
    required this.createdAt,
    required this.companyId,
    required this.templateId,
    required this.productionSteps,
    this.linkedScheduleId,
    this.hasError = false,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json, List<AccountModel> accounts, List<ScheduleModel> schedules) {
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

    // 2. Resolve Status using Schedule table
    String st = 'Pendente';
    String? pDate;
    int? parsedLinkedScheduleId;
    bool hasErr = false;

    final rawStatus = json['Status'] ?? json['field_8445020'];
    if (rawStatus != null && rawStatus.toString().trim().isNotEmpty) {
      final textStatus = rawStatus.toString().trim();
      if (textStatus.toLowerCase().contains('erro')) {
        hasErr = true;
        st = textStatus;
      }
    }

    final idPostagemList = json['idPostagemInstagram'] ?? json['field_7028349'];
    if (!hasErr && idPostagemList != null) {
      if (idPostagemList is List && idPostagemList.isNotEmpty) {
        parsedLinkedScheduleId = idPostagemList.first['id'];
        st = 'Agendado';
      } else if (idPostagemList is String && idPostagemList.trim().isNotEmpty) {
        parsedLinkedScheduleId = int.tryParse(idPostagemList.trim());
        st = 'Agendado';
      } else if (idPostagemList is int) {
        parsedLinkedScheduleId = idPostagemList;
        st = 'Agendado';
      }

      if (parsedLinkedScheduleId != null) {
        try {
          final match = schedules.firstWhere((s) => s.idRow == parsedLinkedScheduleId || s.id == parsedLinkedScheduleId);
          String matchDate = match.dataDaPostagem;
          try {
            if (matchDate.isNotEmpty) {
              final d = DateTime.parse(matchDate).toLocal();
              final day = d.day.toString().padLeft(2, '0');
              final month = d.month.toString().padLeft(2, '0');
              final year = d.year.toString();
              final hour = d.hour.toString().padLeft(2, '0');
              final min = d.minute.toString().padLeft(2, '0');
              matchDate = '$day/$month/$year $hour:$min';
            }
          } catch (_) {}
          pDate = matchDate;
          if (match.postado) {
            st = 'Postado';
          }
        } catch (e) {
          st = 'Agendado';
        }
      } else if (st == 'Agendado' && idPostagemList is String) {
        // If it's a string but couldn't be parsed as an int, still mark as scheduled
        pDate = idPostagemList;
      }
    }

    // 3. Resolve Image URL
    String img = 'https://via.placeholder.com/400x300/F4DCD6/2C2C2C?text=Sem+Imagem';
    final openingImage = json['ImagemDeAbertura'] ?? json['field_6964823'] as List?;
    if (openingImage != null && openingImage.isNotEmpty) {
      img = openingImage.first['url'] ?? img;
    }

    // 3.5. Resolve Video URL
    String? vidUrl;
    final videoLegenda = json['VideoComLegendaPT'] ?? json['field_7007172'];
    if (videoLegenda is List && videoLegenda.isNotEmpty) {
      vidUrl = videoLegenda.first['url'];
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
      videoUrl: vidUrl,
      description: descText,
      date: dateStr,
      postDate: pDate,
      createdAt: parsedDate,
      companyId: cId,
      templateId: tId,
      productionSteps: steps,
      linkedScheduleId: parsedLinkedScheduleId,
      hasError: hasErr,
    );
  }
}
