import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gallery_circle_btn.dart';
import 'photo_image_utils.dart';

/// Full-screen photo gallery viewer with swipe navigation,
/// keyboard arrow-key support, dot indicators, and a thumbnail strip.
///
/// Open via [showDialog]:
/// ```dart
/// showDialog(
///   context: context,
///   useSafeArea: false,
///   builder: (_) => FullscreenGalleryView(
///     images: myImages,
///     startIndex: 0,
///     blockId: block.id,
///   ),
/// );
/// ```
class FullscreenGalleryView extends StatefulWidget {
  final List<String> images;
  final int startIndex;
  final String blockId;

  const FullscreenGalleryView({
    super.key,
    required this.images,
    required this.startIndex,
    required this.blockId,
  });

  @override
  State<FullscreenGalleryView> createState() => _FullscreenGalleryViewState();
}

class _FullscreenGalleryViewState extends State<FullscreenGalleryView> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showUI = true;
  final ScrollController _thumbScrollController = ScrollController();
  final FocusNode _keyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbScrollController.dispose();
    _keyFocusNode.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.images.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _scrollThumbIntoView(int index) {
    if (!_thumbScrollController.hasClients) return;
    const thumbWidth = 68.0; // 60px tile + 8px gap
    final screenWidth =
        MediaQuery.of(context).size.width;
    final targetOffset = (index * thumbWidth) - (screenWidth / 2 - thumbWidth / 2);
    _thumbScrollController.animateTo(
      targetOffset.clamp(0.0, _thumbScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _keyFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _goTo(_currentIndex - 1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _goTo(_currentIndex + 1);
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.pop(context);
            }
          }
        },
        child: GestureDetector(
          // Tap the background to show/hide UI chrome
          onTap: () => setState(() => _showUI = !_showUI),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Main PageView ──
              PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                  _scrollThumbIntoView(idx);
                },
                itemBuilder: (_, idx) => InteractiveViewer(
                  maxScale: 5.0,
                  minScale: 0.8,
                  child: Center(
                    child: Hero(
                      tag: 'gallery_hero_${widget.blockId}_$idx',
                      child: buildRawImage(widget.images[idx]),
                    ),
                  ),
                ),
              ),

              // ── Top bar: counter + close ──
              // Positioned MUST be a direct Stack child for constraints to apply
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showUI ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showUI,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        20, mq.padding.top + 12, 20, 24,
                      ),
                      child: Row(
                        children: [
                          // Image counter badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  '${_currentIndex + 1} / $total',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GalleryCircleBtn(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Left arrow ──
              if (total > 1)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: (_showUI && _currentIndex > 0) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showUI || _currentIndex == 0,
                        child: GalleryCircleBtn(
                          icon: Icons.chevron_left_rounded,
                          size: 32,
                          onTap: () => _goTo(_currentIndex - 1),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Right arrow ──
              if (total > 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: (_showUI && _currentIndex < total - 1) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_showUI || _currentIndex == total - 1,
                        child: GalleryCircleBtn(
                          icon: Icons.chevron_right_rounded,
                          size: 32,
                          onTap: () => _goTo(_currentIndex + 1),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Bottom bar: dots + thumbnail strip ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showUI ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showUI,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16, 20, 16, mq.padding.bottom + 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dot indicators — only when ≤ 10 images
                          if (total <= 10) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(total, (idx) {
                                final active = _currentIndex == idx;
                                return GestureDetector(
                                  onTap: () => _goTo(idx),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: active ? 20.0 : 8.0,
                                    height: 8.0,
                                    decoration: BoxDecoration(
                                      color: active ? Colors.white : Colors.white38,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Thumbnail strip
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              controller: _thumbScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: total,
                              itemBuilder: (_, idx) {
                                final active = _currentIndex == idx;
                                return GestureDetector(
                                  onTap: () => _goTo(idx),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: active ? Colors.white : Colors.white24,
                                        width: active ? 2.5 : 1,
                                      ),
                                      boxShadow: active
                                          ? [
                                              const BoxShadow(
                                                color: Color(0x4DFFFFFF),
                                                blurRadius: 8,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Opacity(
                                        opacity: active ? 1.0 : 0.55,
                                        child: buildRawImage(widget.images[idx]),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
