import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/baserow_service.dart';
import 'models/playlist_model.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final BaserowService _baserowService = BaserowService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isLoading = true;
  List<PlaylistModel> _playlists = [];
  PlaylistSongModel? _currentlyPlayingSong;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
             _currentlyPlayingSong = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _baserowService.fetchPlaylists();
      
      // Group by Name
      final Map<String, List<PlaylistSongModel>> grouped = {};
      for (var row in data) {
        final song = PlaylistSongModel.fromJson(row);
        if (song.playlistName.isEmpty) continue;
        
        if (!grouped.containsKey(song.playlistName)) {
          grouped[song.playlistName] = [];
        }
        grouped[song.playlistName]!.add(song);
      }
      
      final List<PlaylistModel> playlists = grouped.entries.map((e) {
        return PlaylistModel(name: e.key, songs: e.value);
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading playlists: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar playlists: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _playSong(PlaylistSongModel song) async {
    if (song.audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Áudio indisponível para esta música.')),
      );
      return;
    }

    try {
      if (_currentlyPlayingSong?.id == song.id) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      } else {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingSong = song;
        });
        await _audioPlayer.setUrl(song.audioUrl!);
        await _audioPlayer.play();
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> _deleteSong(PlaylistSongModel song) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir a música "${song.audioName ?? 'sem nome'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        if (_currentlyPlayingSong?.id == song.id) {
          await _audioPlayer.stop();
          _currentlyPlayingSong = null;
        }
        await _baserowService.deletePlaylistSong(song.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Música excluída com sucesso.'), backgroundColor: Colors.green),
          );
        }
        await _loadPlaylists();
      } catch (e) {
        print("Error deleting audio: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir música: $e'), backgroundColor: Colors.red),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showAddSongDialog({String? initialPlaylistName}) {
    final TextEditingController nameController = TextEditingController(text: initialPlaylistName);
    final TextEditingController notesController = TextEditingController();
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isUploading = false;

            Future<void> handleSave() async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, informe o nome da playlist.'), backgroundColor: Colors.red),
                );
                return;
              }
              if (selectedFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, selecione um arquivo de áudio.'), backgroundColor: Colors.red),
                );
                return;
              }

              setStateDialog(() {
                isUploading = true;
              });

              try {
                // Upload file
                final uploadedData = await _baserowService.uploadUserFile(
                  selectedFile!.bytes!, 
                  selectedFile!.name
                );

                // Add row
                await _baserowService.addPlaylistSong(
                  playlistName: nameController.text.trim(),
                  notes: notesController.text.trim(),
                  uploadedFileData: uploadedData,
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  _loadPlaylists();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Música adicionada com sucesso!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                print("Error adding song: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
                  );
                }
              } finally {
                setStateDialog(() {
                  isUploading = false;
                });
              }
            }

            return AlertDialog(
              title: Text(initialPlaylistName != null ? 'Adicionar música à $initialPlaylistName' : 'Nova Playlist / Música'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Playlist',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: initialPlaylistName != null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notas / Descrição',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedFile?.name ?? 'Nenhum arquivo selecionado',
                            style: TextStyle(color: selectedFile == null ? AppColors.textLight : AppColors.textDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.audio,
                              withData: true,
                            );
                            if (result != null) {
                              setStateDialog(() {
                                selectedFile = result.files.first;
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file, color: AppColors.terracotta),
                          label: const Text('Selecionar', style: TextStyle(color: AppColors.terracotta)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : handleSave,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.terracotta),
                  child: isUploading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Salvar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        elevation: 1,
        title: const Text('Banco de Músicas Prontas', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, color: AppColors.terracotta),
            onPressed: () => _showAddSongDialog(),
            tooltip: 'Adicionar Nova Playlist',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
        : _playlists.isEmpty 
          ? const Center(child: Text('Nenhuma música encontrada.', style: TextStyle(color: AppColors.textLight)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                  elevation: 0,
                  child: ExpansionTile(
                    title: Text(playlist.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('${playlist.songs.length} música(s)', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                    iconColor: AppColors.terracotta,
                    children: [
                      const Divider(height: 1, color: AppColors.border),
                      ...playlist.songs.map((song) => ListTile(
                        leading: IconButton(
                          icon: Icon(
                            _currentlyPlayingSong?.id == song.id && _isPlaying 
                                ? CupertinoIcons.pause_circle_fill 
                                : CupertinoIcons.play_circle_fill,
                            color: AppColors.terracotta,
                            size: 32,
                          ),
                          onPressed: () => _playSong(song),
                        ),
                        title: Text(song.audioName ?? 'Música sem nome', style: const TextStyle(fontSize: 14)),
                        subtitle: song.notes.isNotEmpty 
                            ? Text(song.notes, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textLight))
                            : null,
                        trailing: IconButton(
                          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 20),
                          tooltip: 'Excluir Música',
                          onPressed: () => _deleteSong(song),
                        ),
                      )).toList(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton.icon(
                          onPressed: () => _showAddSongDialog(initialPlaylistName: playlist.name),
                          icon: const Icon(CupertinoIcons.add, color: AppColors.terracotta, size: 18),
                          label: const Text('Adicionar Música a esta Playlist', style: TextStyle(color: AppColors.terracotta)),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}

