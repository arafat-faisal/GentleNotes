import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../domain/entities/block_entity.dart';
import '../../controllers/editor_block_controller.dart';
import 'audio_playlist_manager_dialog.dart';

class AudioBlock extends ConsumerStatefulWidget {
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
  ConsumerState<AudioBlock> createState() => _AudioBlockState();
}

class _AudioBlockState extends ConsumerState<AudioBlock> with TickerProviderStateMixin {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  bool _showSettings = false;
  int _activeTrackIndex = 0;
  int _deckIndex = 0; // for cassette stack deck view
  bool _playlistExpanded = false; // for playlist view toggle

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  List<Map<String, dynamic>> get _tracks {
    final raw = widget.block.data['audios'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final contentPath = widget.block.content;
    if (contentPath.isNotEmpty) {
      final name = contentPath.startsWith('data:')
          ? 'Voice Note.webm'
          : contentPath.split('/').last.split('\\').last;
      return [
        {'path': contentPath, 'name': name}
      ];
    }
    return [];
  }

  String get _layout => widget.block.attributes['layout'] ?? 'classic';

  Source _getAudioSource(String pathOrUrl) {
    if (pathOrUrl.startsWith('data:')) {
      final base64Str = pathOrUrl.split(',').last;
      return BytesSource(base64Decode(base64Str));
    }
    if (pathOrUrl.startsWith('blob:') || pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return UrlSource(pathOrUrl);
    }
    return DeviceFileSource(pathOrUrl);
  }

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    final tracks = _tracks;
    if (tracks.isNotEmpty && _activeTrackIndex < tracks.length) {
      final path = tracks[_activeTrackIndex]['path'] as String;
      _player.setSource(_getAudioSource(path)).catchError((e) {
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
            _rotationController.repeat();
          } else {
            _waveController.stop();
            _rotationController.stop();
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(AudioBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldAudios = oldWidget.block.data['audios'] as List?;
    final newAudios = widget.block.data['audios'] as List?;
    if (oldAudios != newAudios) {
      final tracks = _tracks;
      if (_activeTrackIndex >= tracks.length) {
        _activeTrackIndex = tracks.isNotEmpty ? tracks.length - 1 : 0;
      }
      if (tracks.isNotEmpty) {
        final path = tracks[_activeTrackIndex]['path'] as String;
        _player.setSource(_getAudioSource(path)).catchError((e) {
          debugPrint('Error setting source: $e');
        });
      }
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _waveController.dispose();
    _rotationController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _selectTrack(int index, {bool autoPlay = false}) {
    final tracks = _tracks;
    if (index < 0 || index >= tracks.length) return;
    setState(() {
      _activeTrackIndex = index;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    final path = tracks[index]['path'] as String;
    if (autoPlay || _isPlaying) {
      _player.play(_getAudioSource(path)).catchError((e) {
        debugPrint('Error playing track: $e');
      });
    } else {
      _player.setSource(_getAudioSource(path)).catchError((e) {
        debugPrint('Error setting track source: $e');
      });
    }
  }

  void _togglePlay() {
    final tracks = _tracks;
    if (tracks.isEmpty) return;
    if (_isPlaying) {
      _player.pause();
    } else {
      final path = tracks[_activeTrackIndex]['path'] as String;
      _player.play(_getAudioSource(path)).catchError((e) {
        debugPrint('Error playing source: $e');
      });
    }
  }

  void _updateLayout(String layout) {
    FocusManager.instance.primaryFocus?.unfocus();
    final newAttrs = Map<String, dynamic>.from(widget.block.attributes)
      ..['layout'] = layout;
    ref
        .read(editorBlockControllerProvider.notifier)
        .updateBlockAttributes(widget.block.id, newAttrs);
  }

  void _updateTracks(List<Map<String, dynamic>> updatedTracks) {
    FocusManager.instance.primaryFocus?.unfocus();
    ref
        .read(editorBlockControllerProvider.notifier)
        .updateBlockData(widget.block.id, {'audios': updatedTracks});
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showPlaylistManager() {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      builder: (ctx) => AudioPlaylistManagerDialog(
        noteId: '',
        tracks: _tracks,
        onUpdate: _updateTracks,
      ),
    );
  }

  void _showDeleteConfirmDialog() {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tracks = _tracks;

    if (tracks.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.music_off_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No audio tracks inside this block', style: TextStyle(color: Colors.grey)),
              if (!widget.readOnly) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showPlaylistManager,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add Audio'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return MouseRegion(
      onEnter: (_) { if (!widget.readOnly) setState(() => _showSettings = true); },
      onExit: (_)  { if (!widget.readOnly) setState(() => _showSettings = false); },
      child: GestureDetector(
        onTapDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          if (!widget.readOnly) setState(() => _showSettings = !_showSettings);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _buildLayoutWidget(tracks, isDark, theme, progress),
                    ),
                  ),
                  if (!widget.readOnly)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _showSettings = !_showSettings);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              _showSettings ? Icons.close_rounded : Icons.tune_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedOpacity(
                opacity: (_showSettings && !widget.readOnly) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(top: (_showSettings && !widget.readOnly) ? 8 : 0),
                  height: (_showSettings && !widget.readOnly) ? 44 : 0,
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

  Widget _buildLayoutWidget(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    switch (_layout) {
      case 'playlist':
        return _buildPlaylistLayout(tracks, isDark, theme, progress);
      case 'carousel':
        return _buildCarouselLayout(tracks, isDark, theme, progress);
      case 'collage':
        return _buildCollageLayout(tracks, isDark, theme, progress);
      case 'grid':
        return _buildGridLayout(tracks, isDark, theme, progress);
      case 'deck':
        return _buildDeckLayout(tracks, isDark, theme, progress);
      case 'pill':
        return _buildPillLayout(tracks, isDark, theme, progress);
      case 'vinyl':
        return _buildVinylLayout(tracks, isDark, theme, progress);
      case 'classic':
      default:
        return _buildClassicLayout(tracks, isDark, theme, progress);
    }
  }

  // ── Classic Waveform layout ──────────────────────────────────────────────────
  Widget _buildClassicLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    final trackName = tracks[_activeTrackIndex]['name'] as String;
    return Container(
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
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
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
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _togglePlay,
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
                              trackName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF3D1F8A),
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
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF7C5ABF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isPlaying)
                  _buildVisualizerWave()
                else
                  _buildStaticWave(isDark),
              ],
            ),
            const SizedBox(height: 10),
            _buildSliderTrack(progress, isDark),
          ],
        ),
      ),
    );
  }

  // ── Minimalist Pill layout ────────────────────────────────────────────────────
  Widget _buildPillLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    final trackName = tracks[_activeTrackIndex]['name'] as String;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF281F4B), const Color(0xFF1B1535)]
                : [const Color(0xFFF3EDFF), const Color(0xFFEBF3FF)],
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _togglePlay,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8B5CF6),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trackName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF3D1F8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF7C5ABF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_isPlaying)
                  _buildVisualizerWave(bars: 3)
                else
                  _buildStaticWave(isDark, bars: 3),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: Stack(
                  children: [
                    Container(color: isDark ? Colors.white10 : Colors.black12),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(color: const Color(0xFF8B5CF6)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Retro Vinyl layout ────────────────────────────────────────────────────────
  Widget _buildVinylLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    final trackName = tracks[_activeTrackIndex]['name'] as String;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161420) : const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2749) : const Color(0xFFE4DFEB),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          _buildVinylRecord(isDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trackName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Track duration: ${_formatDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF8B5CF6),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildInteractiveSlider(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinylRecord(bool isDark) {
    return RotationTransition(
      turns: _rotationController,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111115),
          border: Border.all(color: Colors.white12, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
              ),
            ),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.5),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Playlist / Folder Layout ───────────────────────────────────────────────
  Widget _buildPlaylistLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    final totalTracks = tracks.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B182B) : const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF32284C) : const Color(0xFFE6DFFF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Folder Card Header
          InkWell(
            onTap: () {
              setState(() {
                _playlistExpanded = !_playlistExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C244C) : const Color(0xFFECE5FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_shared_rounded,
                      size: 28,
                      color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Playlist / Folder',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalTracks audio recording${totalTracks > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _playlistExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Playlist List Items
          if (_playlistExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final trackName = track['name']?.toString() ?? 'Track ${index + 1}';
                final isActive = index == _activeTrackIndex;

                return InkWell(
                  onTap: () => _selectTrack(index, autoPlay: true),
                  child: Container(
                    color: isActive
                        ? theme.colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: isActive && _isPlaying
                              ? _buildVisualizerWave(bars: 3)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive ? theme.colorScheme.primary : Colors.grey,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trackName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],

          // Sleek bottom sticky player
          if (_isPlaying || _position != Duration.zero) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231F35) : const Color(0xFFEFEBFA),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 20),
                        onPressed: _activeTrackIndex > 0
                            ? () => _selectTrack(_activeTrackIndex - 1, autoPlay: true)
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          size: 28,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: _togglePlay,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 20),
                        onPressed: _activeTrackIndex < tracks.length - 1
                            ? () => _selectTrack(_activeTrackIndex + 1, autoPlay: true)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tracks[_activeTrackIndex]['name'] ?? 'Playing track',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildSliderTrack(progress, isDark, height: 3),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Cassette Carousel Layout ───────────────────────────────────────────────
  Widget _buildCarouselLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: tracks.length,
            onPageChanged: (idx) => _selectTrack(idx),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final trackName = track['name']?.toString() ?? 'Track ${index + 1}';
              final isActive = index == _activeTrackIndex;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCassetteCard(trackName, isDark, isActive, progress),
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                tracks.length,
                (idx) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _activeTrackIndex == idx ? 16.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: _activeTrackIndex == idx ? theme.colorScheme.primary : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Collage Layout ──────────────────────────────────────────────────────────
  Widget _buildCollageLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    final activeTrack = tracks[_activeTrackIndex];
    final trackName = activeTrack['name']?.toString() ?? 'Track';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero Player
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF211E2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 20,
                child: _buildVinylRecord(isDark),
              ),
              Positioned(
                right: 20,
                left: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trackName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: _togglePlay,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        _buildVisualizerWave(bars: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (tracks.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final name = track['name']?.toString() ?? 'Track';
                final isActive = index == _activeTrackIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => _selectTrack(index, autoPlay: true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : (isDark ? const Color(0xFF181524) : Colors.grey.shade50),
                        border: Border.all(
                          color: isActive ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track ${index + 1}',
                            style: TextStyle(fontSize: 8, color: theme.hintColor),
                          ),
                        ],
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

  // ── Grid Layout ─────────────────────────────────────────────────────────────
  Widget _buildGridLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 80,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final name = track['name']?.toString() ?? 'Track';
        final isActive = index == _activeTrackIndex;

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B192A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  if (isActive) {
                    _togglePlay();
                  } else {
                    _selectTrack(index, autoPlay: true);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive && _isPlaying ? Colors.redAccent : theme.colorScheme.primary,
                  ),
                  child: Icon(
                    isActive && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (isActive) ...[
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: TextStyle(fontSize: 8, color: theme.colorScheme.primary),
                      ),
                    ] else ...[
                      const Text('Track', style: TextStyle(fontSize: 8, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Cassette Stack Deck Layout ──────────────────────────────────────────────
  Widget _buildDeckLayout(List<Map<String, dynamic>> tracks, bool isDark, ThemeData theme, double progress) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    return Center(
      child: SizedBox(
        height: 230,
        width: 320,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List.generate(tracks.length, (idx) {
            final offset = (idx - _deckIndex) % tracks.length;
            final isTop = offset == tracks.length - 1;
            final angle = isTop ? 0.0 : ((idx * 6) % 10 - 5) * (math.pi / 180.0);
            final track = tracks[idx];
            final trackName = track['name']?.toString() ?? 'Track';
            final isActive = idx == _activeTrackIndex;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: isTop ? 0 : 8.0 * (tracks.length - 1 - offset),
              child: Transform.rotate(
                angle: angle,
                child: GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() {
                      _deckIndex = (_deckIndex + 1) % tracks.length;
                      _selectTrack(_deckIndex);
                    });
                  },
                  onDoubleTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _togglePlay();
                  },
                  child: _buildCassetteCard(trackName, isDark, isActive, progress),
                ),
              ),
            );
          }).reversed.toList(),
        ),
      ),
    );
  }

  // ── Cassette Card Drawing Utility ───────────────────────────────────────────
  Widget _buildCassetteCard(String name, bool isDark, bool isActive, double progress) {
    final bgColor = isDark ? const Color(0xFF222026) : const Color(0xFFEFECE5);
    final labelColor = isDark ? const Color(0xFF302E36) : Colors.white;
    final labelTextColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      width: 250,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                name.isEmpty ? 'Voice Tape' : name,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: labelTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSprocket(isActive),
                Container(
                  width: 24,
                  height: 2,
                  color: Colors.grey.shade800,
                ),
                _buildSprocket(isActive),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.circle, size: 5, color: Colors.grey.shade600),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _togglePlay,
                    icon: Icon(
                      isActive && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: const Color(0xFFEC4899),
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  if (isActive)
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    )
                  else
                    const Text(
                      '00:00 / 00:00',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              Icon(Icons.circle, size: 5, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 4),
          if (isActive)
            _buildInteractiveSlider()
          else
            _buildStaticSlider(isDark),
        ],
      ),
    );
  }

  Widget _buildSprocket(bool isActive) {
    final turns = isActive ? _rotationController : const AlwaysStoppedAnimation(0.0);
    return RotationTransition(
      turns: turns,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade800,
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(6, (i) {
              final angle = (i * 30) * 3.1415926535 / 180;
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: 1.5,
                  height: 14,
                  color: Colors.grey.shade400,
                ),
              );
            }),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable Slider Track ──────────────────────────────────────────────────
  Widget _buildSliderTrack(double progress, bool isDark, {double height = 4}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(
            height: height,
            color: isDark ? const Color(0xFF3D2B6B) : const Color(0xFFD6C9FF),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSlider() {
    return SizedBox(
      height: 12,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          activeTrackColor: const Color(0xFFEC4899),
          inactiveTrackColor: Colors.black12,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
        ),
        child: Slider(
          value: _duration.inMilliseconds > 0 ? _position.inMilliseconds.toDouble() : 0.0,
          min: 0.0,
          max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
          onChanged: widget.readOnly
              ? null
              : (val) {
                  _player.seek(Duration(milliseconds: val.toInt()));
                },
        ),
      ),
    );
  }

  Widget _buildStaticSlider(bool isDark) {
    return SizedBox(
      height: 12,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          activeTrackColor: Colors.grey.shade400,
          inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Slider(
          value: 0.0,
          onChanged: null,
        ),
      ),
    );
  }

  // ── Wave Visualizers ───────────────────────────────────────────────────────
  Widget _buildVisualizerWave({int bars = 5}) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(bars, (i) {
            final heights = [10.0, 18.0, 12.0, 20.0, 10.0];
            final offset = (i * 0.2 + _waveController.value) % 1.0;
            final h = heights[i % heights.length] * (0.4 + 0.6 * offset);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStaticWave(bool isDark, {int bars = 5}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(bars, (i) {
        final heights = [8.0, 14.0, 8.0, 16.0, 8.0];
        return Container(
          width: 3,
          height: heights[i % heights.length],
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF4C3882) : const Color(0xFFCBB8FF),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  // ── Control Bar Options Overlay ────────────────────────────────────────────
  Widget _buildControlBar(ThemeData theme, bool isDark) {
    final accent = theme.colorScheme.primary;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xE01C192A) : Colors.white.withValues(alpha: 0.9),
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
              _buildLayoutBtn(Icons.waves_rounded, 'classic', 'Classic Waveform', accent),
              _buildLayoutBtn(Icons.lens_blur_rounded, 'pill', 'Minimalist Pill', accent),
              _buildLayoutBtn(Icons.album_rounded, 'vinyl', 'Retro Vinyl', accent),
              _buildLayoutBtn(Icons.album_outlined, 'cassette', 'Retro Cassette', accent),
              _buildLayoutBtn(Icons.folder_shared_rounded, 'playlist', 'Folder Playlist', accent),
              _buildLayoutBtn(Icons.grid_view_rounded, 'grid', 'Track Grid', accent),
              _buildLayoutBtn(Icons.view_quilt_rounded, 'collage', 'Collage Player', accent),
              _buildLayoutBtn(Icons.layers_rounded, 'deck', 'Stacked Tape Deck', accent),
              const SizedBox(width: 8),
              Container(width: 1, height: 18, color: theme.dividerColor),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.playlist_play_rounded, size: 18, color: Colors.blueAccent),
                onPressed: _showPlaylistManager,
                tooltip: 'Manage Playlist',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                onPressed: _showDeleteConfirmDialog,
                tooltip: 'Remove Audio Block',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutBtn(IconData icon, String type, String tooltip, Color activeColor) {
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
            color: active ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
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
