class ScheduleModel {
  final int id;
  final bool postado;
  final String dataDaPostagem;

  ScheduleModel({
    required this.id,
    required this.postado,
    required this.dataDaPostagem,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? 0,
      postado: json['Postado'] ?? json['field_4470045'] ?? false,
      dataDaPostagem: json['Data da postagem'] ?? json['field_4470006'] ?? '',
    );
  }
}
