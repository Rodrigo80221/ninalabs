class PlaylistSongModel {
  final int id;
  final String playlistName;
  final String notes;
  final String? audioUrl;
  final String? audioName;

  PlaylistSongModel({
    required this.id,
    required this.playlistName,
    required this.notes,
    this.audioUrl,
    this.audioName,
  });

  factory PlaylistSongModel.fromJson(Map<String, dynamic> json) {
    String? url;
    String? name;
    
    if (json['Musica'] != null && json['Musica'] is List && json['Musica'].isNotEmpty) {
      final fileData = json['Musica'].first;
      url = fileData['url'];
      name = fileData['visible_name'] ?? fileData['name'];
    }

    return PlaylistSongModel(
      id: json['id'],
      playlistName: json['Name'] ?? json['field_8169412'] ?? '',
      notes: json['Notes'] ?? json['field_8169413'] ?? '',
      audioUrl: url,
      audioName: name,
    );
  }
}

class PlaylistModel {
  final String name;
  final List<PlaylistSongModel> songs;

  PlaylistModel({
    required this.name,
    required this.songs,
  });
}
