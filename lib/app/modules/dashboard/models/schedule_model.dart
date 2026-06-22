class ScheduleModel {
  final int id;
  final int idRow;
  final bool postado;
  final String dataDaPostagem;

  ScheduleModel({
    required this.id,
    required this.idRow,
    required this.postado,
    required this.dataDaPostagem,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    int parsedIdRow = 0;
    final idRowVal = json['id_row'] ?? json['field_4470004'];
    if (idRowVal is int) {
      parsedIdRow = idRowVal;
    } else if (idRowVal is String) {
      parsedIdRow = int.tryParse(idRowVal) ?? 0;
    }

    return ScheduleModel(
      id: json['id'] ?? 0,
      idRow: parsedIdRow,
      postado: json['Postado'] ?? json['field_4470045'] ?? false,
      dataDaPostagem: json['Data da postagem'] ?? json['field_4470006'] ?? '',
    );
  }
}
