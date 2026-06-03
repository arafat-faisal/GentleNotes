import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'sticker_creator/sticker_creator_controller.dart';
import 'sticker_creator/sticker_preview.dart';
import 'sticker_creator/sticker_category_selector.dart';
import 'sticker_creator/sticker_style_controls.dart';
import 'sticker_creator/sticker_color_controls.dart';
import 'sticker_creator/sticker_text_input.dart';
import 'sticker_creator/sticker_grid.dart';
import 'sticker_creator/sticker_action_bar.dart';

class StickerCreatorSheet extends ConsumerStatefulWidget {
  final Function(String stickerPath) onSelect;

  const StickerCreatorSheet({
    super.key,
    required this.onSelect,
  });

  @override
  ConsumerState<StickerCreatorSheet> createState() => _StickerCreatorSheetState();
}

class _StickerCreatorSheetState extends ConsumerState<StickerCreatorSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRendering = false;

  // Doodle state
  final List<DoodleLine> _doodleLines = [];
  DoodleLine? _currentDoodleLine;
  Color _doodleColor = const Color(0xFF8B5CF6);
  double _doodleBrushSize = 4.0;
  bool _doodleEraser = false;

  // Text Card state
  String _cardText = 'Hello!';
  Color _cardTextColor = Colors.white;
  int _cardGradientIndex = 0;
  double _cardCornerRadius = 16.0;
  double _cardBorderWidth = 0.0;
  final Color _cardBorderColor = Colors.white.withValues(alpha: 0.5);

  // Photo Cutout state
  XFile? _photoFile;
  ui.Image? _photoImage;
  String _photoMask = 'original'; // 'original', 'circle', 'heart', 'star', 'rrect'
  double _photoBorderWidth = 0.0;
  Color _photoBorderColor = const Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await File(file.path).readAsBytes();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final decoded = await completer.future;
      setState(() {
        _photoFile = file;
        _photoImage = decoded;
      });
    }
  }

  Future<void> _createAndInsertSticker() async {
    setState(() => _isRendering = true);

    try {
      Uint8List? pngBytes;
      final size = const Size(300, 300);

      if (_tabController.index == 0) {
        if (_doodleLines.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please draw something first!')),
          );
          setState(() => _isRendering = false);
          return;
        }
        pngBytes = await StickerCreatorController.renderDoodleToBytes(_doodleLines, size);
      } else if (_tabController.index == 1) {
        if (_cardText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter card text!')),
          );
          setState(() => _isRendering = false);
          return;
        }
        pngBytes = await StickerCreatorController.renderTextCardToBytes(
          text: _cardText,
          textColor: _cardTextColor,
          cornerRadius: _cardCornerRadius,
          gradientColors: StickerCreatorController.cardGradients[_cardGradientIndex],
          borderColor: _cardBorderColor,
          borderWidth: _cardBorderWidth,
          size: size,
        );
      } else {
        if (_photoImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a photo first!')),
          );
          setState(() => _isRendering = false);
          return;
        }
        pngBytes = await StickerCreatorController.renderMaskedPhotoToBytes(
          image: _photoImage!,
          maskShape: _photoMask,
          borderWidth: _photoBorderWidth,
          borderColor: _photoBorderColor,
          size: size,
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'custom_sticker_${const Uuid().v4()}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      widget.onSelect(file.path);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Custom Sticker creation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save sticker: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRendering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF13111C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sticker Studio',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              StickerPreview(
                tabIndex: _tabController.index,
                isDark: isDark,
                doodleLines: _doodleLines,
                currentDoodleLine: _currentDoodleLine,
                cardText: _cardText,
                cardTextColor: _cardTextColor,
                cardCornerRadius: _cardCornerRadius,
                cardBorderWidth: _cardBorderWidth,
                cardBorderColor: _cardBorderColor,
                cardGradientColors: StickerCreatorController.cardGradients[_cardGradientIndex],
                photoPath: _photoFile?.path,
                photoMask: _photoMask,
                photoBorderWidth: _photoBorderWidth,
                photoBorderColor: _photoBorderColor,
              ),

              StickerCategorySelector(tabController: _tabController, isDark: isDark),
              const SizedBox(height: 12),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDoodleTab(isDark, theme),
                    _buildTextTab(isDark, theme),
                    _buildPhotoTab(isDark, theme),
                  ],
                ),
              ),

              StickerActionBar(
                isRendering: _isRendering,
                onCancel: () => Navigator.pop(context),
                onConfirm: _createAndInsertSticker,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoodleTab(bool isDark, ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161423) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF2C2740) : const Color(0xFFECE9F3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentDoodleLine = DoodleLine(
                      points: [details.localPosition],
                      color: _doodleEraser ? Colors.transparent : _doodleColor,
                      strokeWidth: _doodleBrushSize,
                    );
                  });
                },
                onPanUpdate: (details) {
                  if (_currentDoodleLine != null) {
                    setState(() {
                      final points = List<Offset>.from(_currentDoodleLine!.points)..add(details.localPosition);
                      _currentDoodleLine = DoodleLine(
                        points: points,
                        color: _currentDoodleLine!.color,
                        strokeWidth: _currentDoodleLine!.strokeWidth,
                      );
                    });
                  }
                },
                onPanEnd: (_) {
                  if (_currentDoodleLine != null) {
                    setState(() {
                      _doodleLines.add(_currentDoodleLine!);
                      _currentDoodleLine = null;
                    });
                  }
                },
                child: CustomPaint(
                  painter: DoodlePainter(
                    lines: _doodleLines,
                    currentLine: _currentDoodleLine,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.undo, color: _doodleLines.isNotEmpty ? theme.colorScheme.primary : Colors.grey),
                onPressed: _doodleLines.isNotEmpty
                    ? () => setState(() => _doodleLines.removeLast())
                    : null,
                tooltip: 'Undo',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                onPressed: () => setState(() {
                  _doodleLines.clear();
                  _currentDoodleLine = null;
                }),
                tooltip: 'Clear All',
              ),
              IconButton(
                icon: Icon(_doodleEraser ? Icons.draw : Icons.auto_fix_normal_rounded),
                color: _doodleEraser ? theme.colorScheme.primary : null,
                onPressed: () => setState(() => _doodleEraser = !_doodleEraser),
                tooltip: _doodleEraser ? 'Pen Mode' : 'Eraser Mode',
              ),
              Expanded(
                child: Slider(
                  value: _doodleBrushSize,
                  min: 1.0,
                  max: 16.0,
                  divisions: 15,
                  label: 'Size: ${_doodleBrushSize.toInt()}',
                  onChanged: (val) => setState(() => _doodleBrushSize = val),
                ),
              ),
            ],
          ),
        ),
        StickerColorControls(
          selectedColor: _doodleColor,
          onColorSelected: (c) => setState(() {
            _doodleColor = c;
            _doodleEraser = false;
          }),
          onGradientSelected: (_) {},
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTextTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StickerTextInput(
            cardText: _cardText,
            onTextChanged: (val) => setState(() => _cardText = val),
            cardTextColor: _cardTextColor,
            onTextColorChanged: (col) => setState(() => _cardTextColor = col),
          ),
          const SizedBox(height: 16),
          StickerColorControls(
            selectedColor: Colors.transparent,
            onColorSelected: (_) {},
            showGradients: true,
            selectedGradientIndex: _cardGradientIndex,
            onGradientSelected: (idx) => setState(() => _cardGradientIndex = idx),
          ),
          const SizedBox(height: 16),
          StickerStyleControls(
            cornerRadius: _cardCornerRadius,
            borderWidth: _cardBorderWidth,
            onCornerRadiusChanged: (val) => setState(() => _cardCornerRadius = val),
            onBorderWidthChanged: (val) => setState(() => _cardBorderWidth = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: StickerGrid(
        onPickPhoto: _pickPhoto,
        photoPath: _photoFile?.path ?? '',
        photoMask: _photoMask,
        onMaskSelected: (shape) => setState(() => _photoMask = shape),
        photoBorderWidth: _photoBorderWidth,
        onBorderWidthChanged: (val) => setState(() => _photoBorderWidth = val),
        photoBorderColor: _photoBorderColor,
        onBorderColorChanged: (col) => setState(() => _photoBorderColor = col),
      ),
    );
  }
}
