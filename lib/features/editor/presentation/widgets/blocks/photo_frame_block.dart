import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../domain/entities/block_entity.dart';
import '../../controllers/editor_block_controller.dart';
import 'fullscreen_gallery_view.dart';
import 'photo_image_utils.dart';

/// A rich photo collection block that supports multiple display layouts:
/// Grid, Carousel, Collage, Polaroid Deck, and Folder Icon.
///
/// When used inside the Quill editor, [onUpdate] and [onRemoved] delegate
/// persistence to the embed builder. Otherwise the Riverpod
/// [editorBlockControllerProvider] is used directly.
class PhotoFrameBlock extends ConsumerStatefulWidget {
  final BlockEntity block;
  final VoidCallback onRemoved;
  final Function(List<String> images, String layout)? onUpdate;
  final bool readOnly;

  const PhotoFrameBlock({
    super.key,
    required this.block,
    required this.onRemoved,
    this.onUpdate,
    this.readOnly = false,
  });

  @override
  ConsumerState<PhotoFrameBlock> createState() => _PhotoFrameBlockState();
}

class _PhotoFrameBlockState extends ConsumerState<PhotoFrameBlock> {
  int _carouselIndex = 0;
  int _polaroidIndex = 0;
  bool _showSettings = false;

  // ── Data accessors ──────────────────────────────────────────────────────────

  List<String> get _images {
    final raw = widget.block.data['images'];
    return raw is List ? List<String>.from(raw) : [];
  }

  String get _layout => widget.block.attributes['layout'] ?? 'grid';

  // ── Mutations ────────────────────────────────────────────────────────────────

  void _updateImages(List<String> newImages) {
    if (widget.onUpdate != null) {
      widget.onUpdate!(newImages, _layout);
    } else {
      ref
          .read(editorBlockControllerProvider.notifier)
          .updateBlockData(widget.block.id, {'images': newImages});
    }
  }

  void _updateLayout(String layout) {
    if (widget.onUpdate != null) {
      widget.onUpdate!(_images, layout);
    } else {
      final newAttrs = Map<String, dynamic>.from(widget.block.attributes)
        ..['layout'] = layout;
      ref
          .read(editorBlockControllerProvider.notifier)
          .updateBlockAttributes(widget.block.id, newAttrs);
    }
  }

  Future<void> _addPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isNotEmpty) {
      final current = List<String>.from(_images);
      for (final f in files) {
        current.add(kIsWeb ? f.path : 'file://${f.path}');
      }
      _updateImages(current);
    }
  }

  void _deletePhoto(int index) {
    if (_images.length <= 1) {
      widget.onRemoved();
      return;
    }
    final current = List<String>.from(_images)..removeAt(index);
    if (_carouselIndex >= current.length) _carouselIndex = current.length - 1;
    if (_polaroidIndex >= current.length) _polaroidIndex = 0;
    _updateImages(current);
  }

  void _openFullscreenGallery(int startIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => FullscreenGalleryView(
        images: _images,
        startIndex: startIndex,
        blockId: widget.block.id,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final images = _images;
    if (images.isEmpty) return _buildEmptyPlaceholder();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) { if (!widget.readOnly) setState(() => _showSettings = true); },
      onExit: (_)  { if (!widget.readOnly) setState(() => _showSettings = false); },
      child: GestureDetector(
        onTap: () {
          if (!widget.readOnly) setState(() => _showSettings = !_showSettings);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Layout view ──
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _buildLayoutWidget(images),
                    ),
                  ),
                  if (!widget.readOnly)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Material(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _showSettings = !_showSettings),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              _showSettings
                                  ? Icons.close_rounded
                                  : Icons.tune_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Config toolbar ──
              AnimatedOpacity(
                opacity: (_showSettings && !widget.readOnly) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                      top: (_showSettings && !widget.readOnly) ? 12 : 0),
                  height: (_showSettings && !widget.readOnly) ? 48 : 0,
                  child: (_showSettings && !widget.readOnly)
                      ? _buildControlBar(theme, isDark)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────────

  Widget _buildEmptyPlaceholder() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.collections_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No photos inside this frame',
                style: TextStyle(color: Colors.grey)),
            if (!widget.readOnly) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _addPhotos,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add Photos'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Layout dispatcher ────────────────────────────────────────────────────────

  Widget _buildLayoutWidget(List<String> images) {
    switch (_layout) {
      case 'carousel': return _buildCarouselLayout(images);
      case 'collage':  return _buildCollageLayout(images);
      case 'polaroid': return _buildPolaroidLayout(images);
      case 'folder':   return _buildFolderLayout(images);
      case 'grid':
      default:         return _buildGridLayout(images);
    }
  }

  // ── Grid layout ──────────────────────────────────────────────────────────────

  Widget _buildGridLayout(List<String> images) {
    final count = images.length;

    if (count == 1) {
      return _buildImageCard(images[0], 0, height: 220);
    }
    if (count == 2) {
      return SizedBox(
        height: 180,
        child: Row(children: [
          Expanded(child: _buildImageCard(images[0], 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildImageCard(images[1], 1)),
        ]),
      );
    }
    if (count == 3) {
      return SizedBox(
        height: 240,
        child: Row(children: [
          Expanded(flex: 2, child: _buildImageCard(images[0], 0)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(children: [
              Expanded(child: _buildImageCard(images[1], 1)),
              const SizedBox(height: 8),
              Expanded(child: _buildImageCard(images[2], 2)),
            ]),
          ),
        ]),
      );
    }

    // 4+ images → 2×2 grid with overflow badge on the 4th cell
    final remaining = count - 4;
    return SizedBox(
      height: 260,
      child: Column(children: [
        Expanded(
          child: Row(children: [
            Expanded(child: _buildImageCard(images[0], 0)),
            const SizedBox(width: 8),
            Expanded(child: _buildImageCard(images[1], 1)),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(children: [
            Expanded(child: _buildImageCard(images[2], 2)),
            const SizedBox(width: 8),
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                _buildImageCard(images[3], 3),
                if (remaining > 0)
                  GestureDetector(
                    onTap: () => _openFullscreenGallery(3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+$remaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Carousel layout ──────────────────────────────────────────────────────────

  Widget _buildCarouselLayout(List<String> images) {
    return SizedBox(
      height: 250,
      child: Stack(children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (idx) => setState(() => _carouselIndex = idx),
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildImageCard(images[index], index),
          ),
        ),
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: _carouselIndex == idx ? 16.0 : 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: _carouselIndex == idx ? Colors.white : Colors.white60,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Collage layout ───────────────────────────────────────────────────────────

  Widget _buildCollageLayout(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImageCard(images[0], 0, height: 200),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length - 1,
              itemBuilder: (_, index) {
                final realIdx = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () => _openFullscreenGallery(realIdx),
                    child: Hero(
                      tag: 'collage_thumb_${widget.block.id}_$realIdx',
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(fit: StackFit.expand, children: [
                            buildRawImage(images[realIdx]),
                            if (!widget.readOnly)
                              Positioned(
                                top: 2, right: 2,
                                child: InkWell(
                                  onTap: () => _deletePhoto(realIdx),
                                  child: const CircleAvatar(
                                    radius: 9,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, size: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ── Polaroid layout ──────────────────────────────────────────────────────────

  Widget _buildPolaroidLayout(List<String> images) {
    return Center(
      child: SizedBox(
        height: 280,
        width: 240,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List.generate(images.length, (idx) {
            final offset = (idx - _polaroidIndex) % images.length;
            final isTop  = offset == images.length - 1;
            final angle  = isTop
                ? 0.0
                : ((idx * 8) % 15 - 7.5) * (math.pi / 180.0);

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: isTop ? 0 : 8.0 * (images.length - 1 - offset),
              child: Transform.rotate(
                angle: angle,
                child: GestureDetector(
                  onTap: () => setState(
                      () => _polaroidIndex = (_polaroidIndex + 1) % images.length),
                  onDoubleTap: () => _openFullscreenGallery(idx),
                  child: Container(
                    width: 210,
                    padding: const EdgeInsets.only(
                        top: 10, left: 10, right: 10, bottom: 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: ClipRect(child: buildRawImage(images[idx])),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Memory ${idx + 1}/${images.length}',
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 11,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (!widget.readOnly)
                            InkWell(
                              onTap: () => _deletePhoto(idx),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                    ]),
                  ),
                ),
              ),
            );
          }).reversed.toList(),
        ),
      ),
    );
  }

  // ── Folder layout ────────────────────────────────────────────────────────────

  Widget _buildFolderLayout(List<String> images) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => _openFullscreenGallery(0),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2E1A47), const Color(0xFF1B1832)]
                : [const Color(0xFFF3EDFF), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF3D2C62) : const Color(0xFFE5DAFF),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3E2C68) : const Color(0xFFE9E0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_shared_rounded,
              size: 32,
              color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Photo Collection / Folder',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${images.length} hand-written notes / photos',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ]),
          ),
          // Stacked thumbnail previews
          SizedBox(
            width: 50,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(
                math.min(images.length, 3),
                (idx) => Positioned(
                  right: idx * 8.0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: buildRawImage(images[idx]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Shared image card ────────────────────────────────────────────────────────

  Widget _buildImageCard(String path, int index, {double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(fit: StackFit.expand, children: [
          GestureDetector(
            onTap: () => _openFullscreenGallery(index),
            child: Hero(
              tag: 'gallery_hero_${widget.block.id}_$index',
              child: buildRawImage(path),
            ),
          ),
          if (!widget.readOnly)
            Positioned(
              top: 8, right: 8,
              child: InkWell(
                onTap: () => _deletePhoto(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Colors.white),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Reorder / manage sheet ───────────────────────────────────────────────────

  void _openReorderSheet(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final images = _images;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13111C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(
                color: isDark ? const Color(0xFF2E2845) : const Color(0xFFE3DCF5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Manage & Reorder Photos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Drag and drop items to reorder the collection',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: images.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setSheetState(() {
                      final item = images.removeAt(oldIndex);
                      images.insert(newIndex, item);
                    });
                    _updateImages(images);
                  },
                  itemBuilder: (_, index) {
                    final path     = images[index];
                    final filename = path.split('/').last;
                    return Card(
                      key: ValueKey('reorder_${path}_$index'),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: isDark
                          ? const Color(0xFF1C192A)
                          : Colors.grey.shade50,
                      elevation: 0,
                      child: ListTile(
                        leading: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.drag_handle_rounded,
                              color: Colors.grey),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 40, height: 40,
                              child: buildRawImage(path),
                            ),
                          ),
                        ]),
                        title: Text(
                          filename.length > 20
                              ? '${filename.substring(0, 10)}...${filename.substring(filename.length - 8)}'
                              : filename,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 20),
                          onPressed: () =>
                              setSheetState(() => _deletePhoto(index)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    await _addPhotos();
                    setSheetState(() {});
                  },
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: const Text('Add More Photos',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── Control bar ──────────────────────────────────────────────────────────────

  Widget _buildControlBar(ThemeData theme, bool isDark) {
    final accent = theme.colorScheme.primary;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xE01C192A)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF2E2845) : const Color(0xFFE3DCF5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLayoutBtn(Icons.grid_on_rounded,        'grid',     'Grid',         accent),
              _buildLayoutBtn(Icons.view_carousel_rounded,  'carousel', 'Carousel',     accent),
              _buildLayoutBtn(Icons.dashboard_rounded,      'collage',  'Collage',      accent),
              _buildLayoutBtn(Icons.layers_rounded,         'polaroid', 'Polaroid Deck',accent),
              _buildLayoutBtn(Icons.folder_rounded,         'folder',   'Folder Icon',  accent),
              const SizedBox(width: 8),
              Container(width: 1, height: 18, color: theme.dividerColor),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.reorder_rounded, size: 18, color: accent),
                onPressed: () => _openReorderSheet(context),
                tooltip: 'Reorder & Manage Photos',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: Icon(Icons.add_photo_alternate_rounded, size: 18, color: accent),
                onPressed: _addPhotos,
                tooltip: 'Add Photos',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.red),
                onPressed: widget.onRemoved,
                tooltip: 'Remove Frame Block',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutBtn(
      IconData icon, String type, String tooltip, Color activeColor) {
    final active = _layout == type;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _updateLayout(type),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active
                ? activeColor.withValues(alpha: 0.15)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? activeColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}
