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
  // Campos originais
  String _fontColor = '#FFFFFF';
  String _fontBorderColor = '#000000';
  int _fontSize = 14;
  int _positionY = 80;
  int _maxLines = 2;

  // Novos campos visuais
  String _fontFamily = 'Poppins';
  int _fontWeight = 600;
  int _borderWidth = 2;
  int _fontOpacity = 100;
  bool _shadowEnabled = true;
  int _shadowOpacity = 55;
  int _shadowDepth = 1;
  String _highlightColor = '#FFD633';

  late TextEditingController _fontColorController;
  late TextEditingController _fontBorderController;
  late TextEditingController _positionYController;
  late TextEditingController _maxLinesController;
  late TextEditingController _highlightColorController;

  static const List<String> _fontFamilies = [
    'Poppins',
    'Montserrat',
    'Inter',
  ];

  static const List<int> _fontWeights = [400, 600, 700, 800];

  @override
  void initState() {
    super.initState();
    _positionY = widget.defaultPositionY;
    _parseConfig(widget.initialValue);
    _fontColorController = TextEditingController(text: _fontColor);
    _fontBorderController = TextEditingController(text: _fontBorderColor);
    _positionYController = TextEditingController(text: _positionY.toString());
    _maxLinesController = TextEditingController(text: _maxLines.toString());
    _highlightColorController = TextEditingController(text: _highlightColor);

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
            if (kv[0] == 'font_family') _fontFamily = kv[1];
            if (kv[0] == 'font_weight') _fontWeight = int.tryParse(kv[1]) ?? 600;
            if (kv[0] == 'border_width') _borderWidth = int.tryParse(kv[1]) ?? 2;
            if (kv[0] == 'font_opacity') _fontOpacity = int.tryParse(kv[1]) ?? 100;
            if (kv[0] == 'shadow_enabled') _shadowEnabled = kv[1] == 'true';
            if (kv[0] == 'shadow_opacity') _shadowOpacity = int.tryParse(kv[1]) ?? 55;
            if (kv[0] == 'shadow_depth') _shadowDepth = int.tryParse(kv[1]) ?? 1;
            if (kv[0] == 'highlight_color') _highlightColor = kv[1];
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
      _fontFamily = value['font_family'] ?? 'Poppins';
      _fontWeight = value['font_weight'] ?? 600;
      _borderWidth = value['border_width'] ?? 2;
      _fontOpacity = value['font_opacity'] ?? 100;
      _shadowEnabled = value['shadow_enabled'] ?? true;
      _shadowOpacity = value['shadow_opacity'] ?? 55;
      _shadowDepth = value['shadow_depth'] ?? 1;
      _highlightColor = value['highlight_color'] ?? '#FFD633';
    }
    // Garante que os valores estao dentro do range valido
    _fontOpacity = _fontOpacity.clamp(0, 100);
    _shadowOpacity = _shadowOpacity.clamp(0, 100);
    _shadowDepth = _shadowDepth.clamp(0, 20);
    _borderWidth = _borderWidth.clamp(0, 10);
    if (!_fontFamilies.contains(_fontFamily)) _fontFamily = 'Poppins';
    if (!_fontWeights.contains(_fontWeight)) _fontWeight = 600;
  }

  void _notifyChange() {
    final result = {
      'font_color': _fontColor,
      'font_border_color': _fontBorderColor,
      'size': _fontSize,
      'position_y': _positionY,
      'max_lines': _maxLines,
      'font_family': _fontFamily,
      'font_weight': _fontWeight,
      'border_width': _borderWidth,
      'font_opacity': _fontOpacity,
      'shadow_enabled': _shadowEnabled,
      'shadow_opacity': _shadowOpacity,
      'shadow_depth': _shadowDepth,
      'highlight_color': _highlightColor,
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
    _highlightColorController.dispose();
    super.dispose();
  }

  // --- Helpers de UI ---

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54, letterSpacing: 0.8),
        ),
      );

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 12));

  Widget _colorField({
    required String label,
    required String value,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    final color = _hexToColor(value);
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                onTap: () {
                  _pickColor(color, (picked) {
                    final hex = _colorToHex(picked);
                    setState(() {
                      controller.text = hex;
                    });
                    onChanged(hex);
                  });
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  onChanged: (val) {
                    onChanged(val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(label),
            Text(
              '${value.toInt()}${suffix ?? ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (val) => onChanged(val),
          ),
        ),
      ],
    );
  }

  FontWeight _toFontWeight(int weight) {
    switch (weight) {
      case 400: return FontWeight.w400;
      case 600: return FontWeight.w600;
      case 700: return FontWeight.w700;
      case 800: return FontWeight.w800;
      default:  return FontWeight.w600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = _hexToColor(_fontColor);
    final previewBorderColor = _hexToColor(_fontBorderColor);
    final previewHighlightColor = _hexToColor(_highlightColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── TIPOGRAFIA ───────────────────────────────────────────
                _sectionLabel('TIPOGRAFIA'),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Font Family
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Font Family'),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            value: _fontFamily,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            items: _fontFamilies.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _fontFamily = val);
                              _notifyChange();
                            },
                          ),
                        ),
                      ],
                    ),
                    // Font Weight
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Font Weight'),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<int>(
                            value: _fontWeight,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            items: _fontWeights.map((w) => DropdownMenuItem(value: w, child: Text(w.toString()))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _fontWeight = val);
                              _notifyChange();
                            },
                          ),
                        ),
                      ],
                    ),
                    // Size
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Size'),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: DropdownButtonFormField<int>(
                            value: _fontSize,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            items: [10, 12, 14, 16, 18, 20, 24, 28, 32].map((s) => DropdownMenuItem(value: s, child: Text(s.toString()))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _fontSize = val);
                              _notifyChange();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Font Opacity (slider)
                const SizedBox(height: 12),
                _sliderField(
                  label: 'Font Opacity',
                  value: _fontOpacity.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  suffix: '%',
                  onChanged: (val) {
                    setState(() => _fontOpacity = val.toInt());
                    _notifyChange();
                  },
                ),

                // ── CORES ────────────────────────────────────────────────
                _sectionLabel('CORES'),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _colorField(
                      label: 'Font Color (Hex)',
                      value: _fontColor,
                      controller: _fontColorController,
                      onChanged: (val) {
                        setState(() => _fontColor = val);
                        _notifyChange();
                      },
                    ),
                    _colorField(
                      label: 'Border Color (Hex)',
                      value: _fontBorderColor,
                      controller: _fontBorderController,
                      onChanged: (val) {
                        setState(() => _fontBorderColor = val);
                        _notifyChange();
                      },
                    ),
                    _colorField(
                      label: 'Highlight Color (Hex)',
                      value: _highlightColor,
                      controller: _highlightColorController,
                      onChanged: (val) {
                        setState(() => _highlightColor = val);
                        _notifyChange();
                      },
                    ),
                  ],
                ),

                // ── BORDA ────────────────────────────────────────────────
                _sectionLabel('BORDA'),
                _sliderField(
                  label: 'Border Width',
                  value: _borderWidth.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  suffix: 'px',
                  onChanged: (val) {
                    setState(() => _borderWidth = val.toInt());
                    _notifyChange();
                  },
                ),

                // ── SOMBRA ───────────────────────────────────────────────
                _sectionLabel('SOMBRA'),
                Row(
                  children: [
                    Switch(
                      value: _shadowEnabled,
                      onChanged: (val) {
                        setState(() => _shadowEnabled = val);
                        _notifyChange();
                      },
                    ),
                    const SizedBox(width: 8),
                    _label('Shadow Enabled'),
                  ],
                ),
                if (_shadowEnabled) ...[
                  const SizedBox(height: 4),
                  _sliderField(
                    label: 'Shadow Opacity',
                    value: _shadowOpacity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    suffix: '%',
                    onChanged: (val) {
                      setState(() => _shadowOpacity = val.toInt());
                      _notifyChange();
                    },
                  ),
                  _sliderField(
                    label: 'Shadow Depth',
                    value: _shadowDepth.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    suffix: 'px',
                    onChanged: (val) {
                      setState(() => _shadowDepth = val.toInt());
                      _notifyChange();
                    },
                  ),
                ],

                // ── POSICAO ──────────────────────────────────────────────
                _sectionLabel('POSICAO'),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Pos Y'),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _positionYController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null) {
                                setState(() => _positionY = parsed);
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
                        _label('max_lines'),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _maxLinesController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              if (parsed != null) {
                                setState(() => _maxLines = parsed);
                                _notifyChange();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── PREVIEW ──────────────────────────────────────────────
                const SizedBox(height: 16),
                const Text('Preview:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Legenda de exemplo / '),
                              TextSpan(text: 'highlight'),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: _fontSize.toDouble(),
                            fontWeight: _toFontWeight(_fontWeight),
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = _borderWidth.toDouble()
                              ..color = previewBorderColor,
                          ),
                        ),
                        // Fill
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Legenda de exemplo / ',
                                style: TextStyle(
                                  color: previewColor.withOpacity(_fontOpacity / 100.0),
                                ),
                              ),
                              TextSpan(
                                text: 'highlight',
                                style: TextStyle(
                                  color: previewHighlightColor,
                                ),
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: _fontSize.toDouble(),
                            fontWeight: _toFontWeight(_fontWeight),
                            shadows: _shadowEnabled
                                ? [
                                    Shadow(
                                      color: Colors.black.withOpacity(_shadowOpacity / 100.0),
                                      offset: Offset(_shadowDepth.toDouble() * 0.5, _shadowDepth.toDouble() * 0.5),
                                    )
                                  ]
                                : null,
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
