import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SubtitleConfigWidget extends StatefulWidget {
  final String title;
  final dynamic initialValue;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final int defaultPositionY;

  const SubtitleConfigWidget({
    super.key,
    required this.title,
    required this.initialValue,
    required this.onChanged,
    this.defaultPositionY = 80,
  });

  @override
  State<SubtitleConfigWidget> createState() => _SubtitleConfigWidgetState();
}

class _SubtitleConfigWidgetState extends State<SubtitleConfigWidget> {
  String _fontColor = '#FFFFFF';
  String _fontBorderColor = '#000000';
  int _fontSize = 14;
  int _positionY = 80;
  int _maxLines = 2;

  late TextEditingController _fontColorController;
  late TextEditingController _fontBorderController;
  late TextEditingController _positionYController;
  late TextEditingController _maxLinesController;

  @override
  void initState() {
    super.initState();
    _positionY = widget.defaultPositionY;
    _parseConfig(widget.initialValue);
    _fontColorController = TextEditingController(text: _fontColor);
    _fontBorderController = TextEditingController(text: _fontBorderColor);
    _positionYController = TextEditingController(text: _positionY.toString());
    _maxLinesController = TextEditingController(text: _maxLines.toString());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notifyChange();
      }
    });
  }

  void _parseConfig(dynamic value) {
    if (value == null) return;
    if (value is String) {
      if (value.isEmpty) return;
      try {
        final parts = value.replaceFirst('Resposta: ', '').split(' | ');
        for (var part in parts) {
          final kv = part.split(': ');
          if (kv.length == 2) {
            if (kv[0] == 'font_color') _fontColor = kv[1];
            if (kv[0] == 'font_border_color') _fontBorderColor = kv[1];
            if (kv[0] == 'size') _fontSize = int.tryParse(kv[1]) ?? 14;
            if (kv[0] == 'position_y') _positionY = int.tryParse(kv[1]) ?? widget.defaultPositionY;
            if (kv[0] == 'max_lines') _maxLines = int.tryParse(kv[1]) ?? 2;
          }
        }
      } catch (e) {
        debugPrint("Error parsing subtitle config string: $e");
      }
    } else if (value is Map) {
      _fontColor = value['font_color'] ?? '#FFFFFF';
      _fontBorderColor = value['font_border_color'] ?? '#000000';
      _fontSize = value['size'] ?? 14;
      _positionY = value['position_y'] ?? widget.defaultPositionY;
      _maxLines = value['max_lines'] ?? 2;
    }
  }

  void _notifyChange() {
    final result = {
      'font_color': _fontColor,
      'font_border_color': _fontBorderColor,
      'size': _fontSize,
      'position_y': _positionY,
      'max_lines': _maxLines,
    };
    widget.onChanged(result);
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      try {
        return Color(int.parse(hex, radix: 16));
      } catch (_) {
        return Colors.transparent;
      }
    }
    return Colors.transparent;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _pickColor(Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        Color pickerColor = currentColor;
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                onColorChanged(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fontColorController.dispose();
    _fontBorderController.dispose();
    _positionYController.dispose();
    _maxLinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _hexToColor(_fontColor);
    final previewBorderColor = _hexToColor(_fontBorderColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Font Color (Hex)', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  _pickColor(previewColor, (color) {
                                    final hex = _colorToHex(color);
                                    setState(() {
                                      _fontColor = hex;
                                      _fontColorController.text = hex;
                                    });
                                    _notifyChange();
                                  });
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: previewColor,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _fontColorController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _fontColor = val;
                                    });
                                    _notifyChange();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Border Color (Hex)', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  _pickColor(previewBorderColor, (color) {
                                    final hex = _colorToHex(color);
                                    setState(() {
                                      _fontBorderColor = hex;
                                      _fontBorderController.text = hex;
                                    });
                                    _notifyChange();
                                  });
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: previewBorderColor,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _fontBorderController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _fontBorderColor = val;
                                    });
                                    _notifyChange();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Size', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: DropdownButtonFormField<int>(
                            value: _fontSize,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: [10, 12, 14, 16, 18, 20, 24, 28, 32].map((size) {
                              return DropdownMenuItem(value: size, child: Text(size.toString()));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _fontSize = val;
                                });
                                _notifyChange();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pos Y', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _positionYController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty) {
                                final parsed = int.tryParse(val);
                                if (parsed != null) {
                                  setState(() {
                                    _positionY = parsed;
                                  });
                                  _notifyChange();
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('max_lines', style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _maxLinesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty) {
                                final parsed = int.tryParse(val);
                                if (parsed != null) {
                                  setState(() {
                                    _maxLines = parsed;
                                  });
                                  _notifyChange();
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Preview:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Colors.black, Colors.white],
                      stops: [0.5, 0.5],
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      children: [
                        // Border/Stroke
                        Text(
                          'Exemplo de Legenda / Subtitle Example',
                          style: TextStyle(
                            fontSize: _fontSize.toDouble(),
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = previewBorderColor,
                          ),
                        ),
                        // Fill
                        Text(
                          'Exemplo de Legenda / Subtitle Example',
                          style: TextStyle(
                            fontSize: _fontSize.toDouble(),
                            fontWeight: FontWeight.bold,
                            color: previewColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
