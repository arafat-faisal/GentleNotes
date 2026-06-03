import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DoodleLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DoodleLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

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

  // ── Doodle state ─────────────────────────────────────────────────
  final List<DoodleLine> _doodleLines = [];
  DoodleLine? _currentDoodleLine;
  Color _doodleColor = const Color(0xFF8B5CF6);
  double _doodleBrushSize = 4.0;
  bool _doodleEraser = false;

  final List<Color> _curatedColors = [
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFFACC15), // Yellow
    const Color(0xFF10B981), // Green
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF1F2937), // Dark Gray/Black
    const Color(0xFFFFFFFF), // White
    const Color(0xFFFCA5A5), // Pastel Red
    const Color(0xFFFED7AA), // Pastel Orange
    const Color(0xFFFEF08A), // Pastel Yellow
    const Color(0xFFA7F3D0), // Pastel Green
    const Color(0xFFBFDBFE), // Pastel Blue
    const Color(0xFFDDD6FE), // Pastel Purple
  ];

  // ── Text Card state ──────────────────────────────────────────────
  String _cardText = 'Hello!';
  Color _cardTextColor = Colors.white;
  int _cardGradientIndex = 0;
  double _cardCornerRadius = 16.0;
  double _cardBorderWidth = 0.0;
  final Color _cardBorderColor = Colors.white.withValues(alpha: 0.5);

  final List<List<Color>> _cardGradients = [
    [const Color(0xFF8B5CF6), const Color(0xFFEC4899)], // Lavender Mist
    [const Color(0xFFF97316), const Color(0xFFEF4444)], // Sunset Glow
    [const Color(0xFF06B6D4), const Color(0xFF3B82F6)], // Ocean Wave
    [const Color(0xFF10B981), const Color(0xFF059669)], // Forest Mint
    [const Color(0xFF1F2937), const Color(0xFF111827)], // Cyber Dark
    [Colors.white, Colors.white], // Pure White
  ];

  // ── Photo Cutout state ───────────────────────────────────────────
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

  // ── Render and Save Sticker ──────────────────────────────────────
  Future<void> _createAndInsertSticker() async {
    setState(() => _isRendering = true);

    try {
      Uint8List? pngBytes;
      final size = const Size(300, 300);

      if (_tabController.index == 0) {
        // Doodle mode
        if (_doodleLines.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please draw something first!')),
          );
          setState(() => _isRendering = false);
          return;
        }
        pngBytes = await _renderDoodleToBytes(_doodleLines, size);
      } else if (_tabController.index == 1) {
        // Text Card mode
        if (_cardText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter card text!')),
          );
          setState(() => _isRendering = false);
          return;
        }
        pngBytes = await _renderTextCardToBytes(
          text: _cardText,
          textColor: _cardTextColor,
          cornerRadius: _cardCornerRadius,
          gradientColors: _cardGradients[_cardGradientIndex],
          borderColor: _cardBorderColor,
          borderWidth: _cardBorderWidth,
          size: size,
        );
      } else {
        // Photo Mask mode
        if (_photoImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a photo first!')),
          );
          setState(() => _isRendering = false);
          return;
        }
        pngBytes = await _renderMaskedPhotoToBytes(
          image: _photoImage!,
          maskShape: _photoMask,
          borderWidth: _photoBorderWidth,
          borderColor: _photoBorderColor,
          size: size,
        );
      }

      final bytes = pngBytes;
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'custom_sticker_${const Uuid().v4()}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // callback and pop
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
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              // Sheet Header
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

              // Live Preview Section
              _buildLivePreview(isDark),

              // TabBar selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B1829) : const Color(0xFFF3F1FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Doodle'),
                    Tab(text: 'Text Card'),
                    Tab(text: 'Photo Mask'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content Area
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), // avoid collision with canvas gestures
                  children: [
                    _buildDoodleTab(isDark, theme),
                    _buildTextTab(isDark, theme),
                    _buildPhotoTab(isDark, theme),
                  ],
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isRendering ? null : _createAndInsertSticker,
                        child: _isRendering
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Create & Insert'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Live Preview Rendering ───────────────────────────────────────
  Widget _buildLivePreview(bool isDark) {
    return Container(
      width: 160,
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1B28) : const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2740) : const Color(0xFFECE9F3),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 140,
          height: 140,
          child: Builder(
            builder: (context) {
              if (_tabController.index == 0) {
                // Doodle Preview
                return CustomPaint(
                  painter: DoodlePainter(
                    lines: _doodleLines,
                    currentLine: _currentDoodleLine,
                  ),
                );
              } else if (_tabController.index == 1) {
                // Text Card Preview
                final grad = _cardGradients[_cardGradientIndex];
                final hasGrad = grad.length > 1;

                return Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasGrad ? null : grad.first,
                      gradient: hasGrad ? LinearGradient(colors: grad) : null,
                      borderRadius: BorderRadius.circular(_cardCornerRadius / 2),
                      border: _cardBorderWidth > 0
                          ? Border.all(color: _cardBorderColor, width: _cardBorderWidth / 2)
                          : null,
                    ),
                    child: IntrinsicWidth(
                      child: Center(
                        child: Text(
                          _cardText.isEmpty ? 'Sample' : _cardText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _cardTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // Photo Mask Preview
                if (_photoFile == null) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_outlined, size: 36, color: Colors.grey),
                        SizedBox(height: 6),
                        Text('No Image Selected', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                Widget imgWidget = Image.file(
                  File(_photoFile!.path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );

                if (_photoMask != 'original') {
                  imgWidget = ClipPath(
                    clipper: ShapeMaskClipper(_photoMask),
                    child: imgWidget,
                  );
                }

                return Stack(
                  children: [
                    Positioned.fill(child: imgWidget),
                    if (_photoBorderWidth > 0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BorderShapePainter(
                            shape: _photoMask,
                            borderColor: _photoBorderColor,
                            borderWidth: _photoBorderWidth,
                          ),
                        ),
                      ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Doodle Pad UI ──────────────────────────────────────────
  Widget _buildDoodleTab(bool isDark, ThemeData theme) {
    return Column(
      children: [
        // Doodle Draw Canvas Box
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
                  // Use details.localPosition directly as it's relative to the GestureDetector!
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
                      if (_doodleEraser) {
                        // Apply eraser by adding translucent line or filtering points.
                        // For simplicity in a transparent canvas, we can paint with a blending mode or backgound color.
                        // But since we want transparent cutout stickers, we paint eraser lines with BlendMode.clear!
                        // Our DoodlePainter supports BlendMode.clear when color is Colors.transparent.
                        _doodleLines.add(_currentDoodleLine!);
                      } else {
                        _doodleLines.add(_currentDoodleLine!);
                      }
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

        // Controls bar (Brush size, undo, clear, eraser)
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

        // Curated Color Presets
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _curatedColors.length,
            itemBuilder: (context, index) {
              final c = _curatedColors[index];
              final isSelected = _doodleColor == c && !_doodleEraser;

              return GestureDetector(
                onTap: () => setState(() {
                  _doodleColor = c;
                  _doodleEraser = false;
                }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (c == Colors.white ? Colors.grey.shade300 : Colors.transparent),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Tab 2: Text Card UI ───────────────────────────────────────────
  Widget _buildTextTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Text Input Field
          TextField(
            decoration: InputDecoration(
              labelText: 'Sticker Text',
              hintText: 'Enter typography text...',
              prefixIcon: const Icon(Icons.text_fields),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            maxLength: 32,
            onChanged: (val) => setState(() => _cardText = val),
          ),
          const SizedBox(height: 12),

          // Text Color Row
          const Text('Text Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _colorCircle(Colors.white, 'White'),
              _colorCircle(Colors.black, 'Black'),
              _colorCircle(const Color(0xFFFACC15), 'Yellow'),
              _colorCircle(const Color(0xFFF43F5E), 'Red'),
              _colorCircle(const Color(0xFF60A5FA), 'Blue'),
            ],
          ),
          const SizedBox(height: 16),

          // Gradients Presets Selector
          const Text('Background Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _cardGradients.length,
              itemBuilder: (context, index) {
                final grad = _cardGradients[index];
                final isSelected = _cardGradientIndex == index;
                final hasGrad = grad.length > 1;

                return GestureDetector(
                  onTap: () => setState(() => _cardGradientIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 70,
                    decoration: BoxDecoration(
                      color: hasGrad ? null : grad.first,
                      gradient: hasGrad ? LinearGradient(colors: grad) : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 3.0 : 1.0,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_circle_outline,
                            color: grad.first.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Card Parameters
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Corner Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    Slider(
                      value: _cardCornerRadius,
                      min: 0.0,
                      max: 48.0,
                      divisions: 12,
                      label: _cardCornerRadius.toInt().toString(),
                      onChanged: (val) => setState(() => _cardCornerRadius = val),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Border Width', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    Slider(
                      value: _cardBorderWidth,
                      min: 0.0,
                      max: 6.0,
                      divisions: 6,
                      label: _cardBorderWidth.toInt().toString(),
                      onChanged: (val) => setState(() => _cardBorderWidth = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorCircle(Color color, String tooltip) {
    final isSelected = _cardTextColor == color;
    return GestureDetector(
      onTap: () => setState(() => _cardTextColor = color),
      child: Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (color == Colors.white ? Colors.grey.shade300 : Colors.transparent),
              width: isSelected ? 3 : 1,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                )
              : null,
        ),
      ),
    );
  }

  // ── Tab 3: Photo Mask UI ──────────────────────────────────────────
  Widget _buildPhotoTab(bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Select Image Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.image_search_rounded),
            label: Text(_photoFile == null ? 'Select Photo from Gallery' : 'Change Photo'),
            onPressed: _pickPhoto,
          ),
          const SizedBox(height: 20),

          // Mask Shape Presets
          const Text('Cutout Shape Mask', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _maskBtn('original', Icons.crop_original_rounded, 'Original'),
              _maskBtn('circle', Icons.circle_outlined, 'Circle'),
              _maskBtn('rrect', Icons.rounded_corner_rounded, 'RRect'),
              _maskBtn('heart', Icons.favorite_border_rounded, 'Heart'),
              _maskBtn('star', Icons.star_border_rounded, 'Star'),
            ],
          ),
          const SizedBox(height: 20),

          // Border Options
          const Text('Sticker Border Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Slider(
            value: _photoBorderWidth,
            min: 0.0,
            max: 10.0,
            divisions: 10,
            label: 'Border: ${_photoBorderWidth.toInt()}px',
            onChanged: (val) => setState(() => _photoBorderWidth = val),
          ),

          // Border Color Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _photoBorderColorCircle(const Color(0xFF8B5CF6), 'Purple'),
              _photoBorderColorCircle(const Color(0xFFEF4444), 'Red'),
              _photoBorderColorCircle(const Color(0xFF10B981), 'Green'),
              _photoBorderColorCircle(const Color(0xFFFACC15), 'Yellow'),
              _photoBorderColorCircle(Colors.white, 'White'),
              _photoBorderColorCircle(Colors.black, 'Black'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _maskBtn(String shape, IconData icon, String label) {
    final isSelected = _photoMask == shape;
    final theme = Theme.of(context);

    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey),
          onPressed: () => setState(() => _photoMask = shape),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: isSelected ? theme.colorScheme.primary : Colors.grey)),
      ],
    );
  }

  Widget _photoBorderColorCircle(Color color, String tooltip) {
    final isSelected = _photoBorderColor == color;
    return GestureDetector(
      onTap: () => setState(() => _photoBorderColor = color),
      child: Tooltip(
        message: tooltip,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (color == Colors.white ? Colors.grey.shade300 : Colors.transparent),
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Doodle Painter ─────────────────────────────────────────────────
class DoodlePainter extends CustomPainter {
  final List<DoodleLine> lines;
  final DoodleLine? currentLine;

  DoodlePainter({
    required this.lines,
    this.currentLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawSingleLine(DoodleLine line) {
      if (line.points.isEmpty) return;
      paint.color = line.color;
      paint.strokeWidth = line.strokeWidth;
      
      // If transparent, act as eraser using BlendMode.clear
      if (line.color == Colors.transparent) {
        paint.blendMode = BlendMode.clear;
      } else {
        paint.blendMode = BlendMode.srcOver;
      }

      final path = Path();
      path.moveTo(line.points.first.dx, line.points.first.dy);
      for (int i = 1; i < line.points.length; i++) {
        path.lineTo(line.points[i].dx, line.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw past lines
    for (final line in lines) {
      drawSingleLine(line);
    }

    // Draw current line
    if (currentLine != null) {
      drawSingleLine(currentLine!);
    }
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) => true;
}

// ── Shape Mask Clipper ──────────────────────────────────────────────
class ShapeMaskClipper extends CustomClipper<Path> {
  final String shape;
  ShapeMaskClipper(this.shape);

  @override
  Path getClip(Size size) {
    final path = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (shape == 'circle') {
      path.addOval(rect);
    } else if (shape == 'rrect') {
      path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    } else if (shape == 'heart') {
      final w = size.width;
      final h = size.height;
      path.moveTo(w * 0.5, h * 0.25);
      path.cubicTo(w * 0.2, h * 0.05, w * 0.0, h * 0.25, w * 0.0, h * 0.5);
      path.cubicTo(w * 0.0, h * 0.75, w * 0.25, h * 0.9, w * 0.5, h);
      path.cubicTo(w * 0.75, h * 0.9, w * 1.0, h * 0.75, w * 1.0, h * 0.5);
      path.cubicTo(w * 1.0, h * 0.25, w * 0.8, h * 0.05, w * 0.5, h * 0.25);
      path.close();
    } else if (shape == 'star') {
      final double cx = size.width / 2;
      final double cy = size.height / 2;
      final int points = 5;
      final double outerRadius = size.width / 2;
      final double innerRadius = size.width / 4;
      double angle = -3.141592653589793 / 2;
      final double step = 3.141592653589793 / points;

      path.moveTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      for (int i = 0; i < points; i++) {
        angle += step;
        path.lineTo(cx + innerRadius * cos(angle), cy + innerRadius * sin(angle));
        angle += step;
        path.lineTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      }
      path.close();
    } else {
      path.addRect(rect);
    }
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

// ── Border Shape Painter ───────────────────────────────────────────
class BorderShapePainter extends CustomPainter {
  final String shape;
  final Color borderColor;
  final double borderWidth;

  BorderShapePainter({
    required this.shape,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth / 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path();

    if (shape == 'circle') {
      canvas.drawOval(rect, paint);
    } else if (shape == 'rrect') {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)), paint);
    } else if (shape == 'heart') {
      final w = size.width;
      final h = size.height;
      path.moveTo(w * 0.5, h * 0.25);
      path.cubicTo(w * 0.2, h * 0.05, w * 0.0, h * 0.25, w * 0.0, h * 0.5);
      path.cubicTo(w * 0.0, h * 0.75, w * 0.25, h * 0.9, w * 0.5, h);
      path.cubicTo(w * 0.75, h * 0.9, w * 1.0, h * 0.75, w * 1.0, h * 0.5);
      path.cubicTo(w * 1.0, h * 0.25, w * 0.8, h * 0.05, w * 0.5, h * 0.25);
      path.close();
      canvas.drawPath(path, paint);
    } else if (shape == 'star') {
      final double cx = size.width / 2;
      final double cy = size.height / 2;
      final int points = 5;
      final double outerRadius = size.width / 2;
      final double innerRadius = size.width / 4;
      double angle = -3.141592653589793 / 2;
      final double step = 3.141592653589793 / points;

      path.moveTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      for (int i = 0; i < points; i++) {
        angle += step;
        path.lineTo(cx + innerRadius * cos(angle), cy + innerRadius * sin(angle));
        angle += step;
        path.lineTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
      }
      path.close();
      canvas.drawPath(path, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BorderShapePainter oldDelegate) => true;
}

// ── Rendering helper algorithms (Offscreen painting to PNG bytes) ──

Future<Uint8List> _renderDoodleToBytes(List<DoodleLine> lines, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  for (final line in lines) {
    if (line.points.isEmpty) continue;
    
    if (line.color == Colors.transparent) {
      paint.blendMode = BlendMode.clear;
      paint.color = Colors.black; // color value doesn't matter for clear
    } else {
      paint.blendMode = BlendMode.srcOver;
      paint.color = line.color;
    }
    paint.strokeWidth = line.strokeWidth * 2; // scale stroke for 300x300 canvas

    final path = Path();
    // Scale drawing coordinates from 140x140 preview to 300x300 export canvas
    final scale = size.width / 140.0;
    
    path.moveTo(line.points.first.dx * scale, line.points.first.dy * scale);
    for (int i = 1; i < line.points.length; i++) {
      path.lineTo(line.points[i].dx * scale, line.points[i].dy * scale);
    }
    canvas.drawPath(path, paint);
  }

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<Uint8List> _renderTextCardToBytes({
  required String text,
  required Color textColor,
  required double cornerRadius,
  required List<Color> gradientColors,
  required Color borderColor,
  required double borderWidth,
  required Size size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

  final rect = Rect.fromLTWH(0, 0, size.width, size.height);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius * 2));

  // Background
  final bgPaint = Paint();
  if (gradientColors.length == 1) {
    bgPaint.color = gradientColors.first;
  } else {
    bgPaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: gradientColors,
    ).createShader(rect);
  }
  canvas.drawRRect(rrect, bgPaint);

  // Border
  if (borderWidth > 0) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2;
    canvas.drawRRect(rrect, borderPaint);
  }

  // Text
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 32, // Large print size
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  textPainter.layout(maxWidth: size.width - 48);

  final textX = (size.width - textPainter.width) / 2;
  final textY = (size.height - textPainter.height) / 2;
  textPainter.paint(canvas, Offset(textX, textY));

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<Uint8List> _renderMaskedPhotoToBytes({
  required ui.Image image,
  required String maskShape,
  required double borderWidth,
  required Color borderColor,
  required Size size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

  final rect = Rect.fromLTWH(0, 0, size.width, size.height);
  final path = Path();

  if (maskShape == 'circle') {
    path.addOval(rect);
  } else if (maskShape == 'rrect') {
    path.addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(48)));
  } else if (maskShape == 'heart') {
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, h * 0.25);
    path.cubicTo(w * 0.2, h * 0.05, w * 0.0, h * 0.25, w * 0.0, h * 0.5);
    path.cubicTo(w * 0.0, h * 0.75, w * 0.25, h * 0.9, w * 0.5, h);
    path.cubicTo(w * 0.75, h * 0.9, w * 1.0, h * 0.75, w * 1.0, h * 0.5);
    path.cubicTo(w * 1.0, h * 0.25, w * 0.8, h * 0.05, w * 0.5, h * 0.25);
    path.close();
  } else if (maskShape == 'star') {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final int points = 5;
    final double outerRadius = size.width / 2;
    final double innerRadius = size.width / 4;
    double angle = -3.141592653589793 / 2;
    final double step = 3.141592653589793 / points;

    path.moveTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
    for (int i = 0; i < points; i++) {
      angle += step;
      path.lineTo(cx + innerRadius * cos(angle), cy + innerRadius * sin(angle));
      angle += step;
      path.lineTo(cx + outerRadius * cos(angle), cy + outerRadius * sin(angle));
    }
    path.close();
  } else {
    path.addRect(rect);
  }

  canvas.save();
  canvas.clipPath(path);

  // Draw photo covered to size
  paintImage(
    canvas: canvas,
    rect: rect,
    image: image,
    fit: BoxFit.cover,
  );
  canvas.restore();

  // Draw border on top
  if (borderWidth > 0) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 2;
      
    if (maskShape == 'circle') {
      canvas.drawOval(rect, borderPaint);
    } else if (maskShape == 'rrect') {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(48)), borderPaint);
    } else {
      canvas.drawPath(path, borderPaint);
    }
  }

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
