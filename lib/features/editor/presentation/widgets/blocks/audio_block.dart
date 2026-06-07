import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../domain/entities/block_entity.dart';

class AudioBlock extends StatefulWidget {
  final BlockEntity block;
  final VoidCallback onRemoved;
  final bool readOnly;

  const AudioBlock({
    super.key,
    required this.block,
    required this.onRemoved,
    this.readOnly = false,
  });

  @override
  State<AudioBlock> createState() => _AudioBlockState();
}

class _AudioBlockState extends State<AudioBlock> with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _waveController;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final filePath = widget.block.content;
    if (filePath.isNotEmpty) {
      _player.setSource(DeviceFileSource(filePath)).catchError((e) {
        debugPrint('Error setting source: $e');
      });
    }

    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (_isPlaying) {
            _waveController.repeat(reverse: true);
          } else {
            _waveController.stop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _waveController.dispose();
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filePath = widget.block.content;
    final fileName = filePath.split('/').last;

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTapDown: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2D1F5E), const Color(0xFF1E1A30)]
                : [const Color(0xFFF0EBFF), const Color(0xFFE8F4FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Play/Pause button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        if (_isPlaying) {
                          _player.pause();
                        } else {
                          _player.play(DeviceFileSource(filePath));
                        }
                      },
                      icon: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and duration metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.mic_rounded, size: 13, color: Color(0xFF8B5CF6)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                fileName.isEmpty ? 'Audio Recording' : fileName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF3D1F8A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Inter',
                            color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF7C5ABF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Waveform animation
                  if (_isPlaying)
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final heights = [10.0, 18.0, 12.0, 20.0, 10.0];
                            final offset = (i * 0.2 + _waveController.value) % 1.0;
                            final h = heights[i] * (0.4 + 0.6 * offset);
                            return Container(
                              width: 3,
                              height: h,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        );
                      },
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [8.0, 14.0, 8.0, 16.0, 8.0].map((h) => Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF4C3882) : const Color(0xFFCBB8FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )).toList(),
                    ),
                  if (!widget.readOnly) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                SizedBox(width: 8),
                                Text('Delete Audio Block', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            content: const Text('Remove this audio block from the editor?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.pop(ctx);
                                  widget.onRemoved();
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(
                      height: 4,
                      color: isDark ? const Color(0xFF3D2B6B) : const Color(0xFFD6C9FF),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 4,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Seek control slider
              SizedBox(
                height: 16,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds.toDouble()
                        : 0.0,
                    min: 0.0,
                    max: _duration.inMilliseconds > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: widget.readOnly ? null : (val) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _player.seek(Duration(milliseconds: val.toInt()));
                    },
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
