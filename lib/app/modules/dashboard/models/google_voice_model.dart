class GoogleVoiceModel {
  final int id;
  final String name;
  final String style;
  final String? audioUrl;
  final String? audioEnglishUrl;

  GoogleVoiceModel({
    required this.id,
    required this.name,
    required this.style,
    this.audioUrl,
    this.audioEnglishUrl,
  });

  factory GoogleVoiceModel.fromJson(Map<String, dynamic> json) {
    String? getFileUrl(dynamic field) {
      if (field is List && field.isNotEmpty) {
        return field[0]['url'];
      }
      return null;
    }

    return GoogleVoiceModel(
      id: json['id'] ?? 0,
      name: json['Nome'] ?? json['field_9192355'] ?? '',
      style: json['Estilo'] ?? json['field_9192356'] ?? '',
      audioUrl: getFileUrl(json['Audio'] ?? json['field_9192360']),
      audioEnglishUrl: getFileUrl(json['AudioEnglish'] ?? json['field_9192473']),
    );
  }
}
