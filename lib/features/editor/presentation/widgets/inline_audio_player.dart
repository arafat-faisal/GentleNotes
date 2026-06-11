import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'blocks/audio_playlist_manager_dialog.dart';

class InlineAudioPlayer extends StatefulWidget {
  final String? filePath;
  final String? name;
  final List<Map<String, String>>? tracks;
  final VoidCallback? onDelete;
  final String layout;
  final Function(String)? onLayoutChanged;
  final Function(List<Map<String, String>>)? onTracksChanged;

  const InlineAudioPlayer({
    super.key,
    this.filePath,
    this.name,
    this.tracks,
    this.onDelete,
    this.layout = 'classic',
    this.onLayoutChanged,
    this.onTracksChanged,
  });

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> with TickerProviderStateMixin {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  late AnimationController _waveController;
  late AnimationController _rotationController;
  bool _showSettings = false;
  int _activeTrackIndex = 0;
  int _deckIndex = 0; // for cassette stack deck view
  bool _playlistExpanded = false; // for playlist folder expansion

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  List<Map<String, String>> get _tracks {
    if (widget.tracks != null && widget.tracks!.isNotEmpty) {
      return widget.tracks!;
    }
    if (widget.filePath != null && widget.filePath!.isNotEmpty) {
      return [
        {
          'path': widget.filePath!,
          'name': widget.name ?? 'Voice Note',
        }
      ];
    }
    return [];
  }

  Source _getAudioSource(String pathOrUrl) {
    if (pathOrUrl.startsWith('data:')) {
      final base64Str = pathOrUrl.split(',').last;
      return BytesSource(base64Decode(base64Str));
    }
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://') || pathOrUrl.startsWith('blob:')) {
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
      final path = tracks[_activeTrackIndex]['path'] ?? '';
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
  void didUpdateWidget(InlineAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracks != widget.tracks || oldWidget.filePath != widget.filePath) {
      final tracks = _tracks;
      if (_activeTrackIndex >= tracks.length) {
        _activeTrackIndex = tracks.isNotEmpty ? tracks.length - 1 : 0;
      }
      if (tracks.isNotEmpty) {
        final path = tracks[_activeTrackIndex]['path'] ?? '';
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

    final path = tracks[index]['path'] ?? '';
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
      final path = tracks[_activeTrackIndex]['path'] ?? '';
      _player.play(_getAudioSource(path)).catchError((e) {
        debugPrint('Error playing source: $e');
      });
    }
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
        onUpdate: (updated) {
          if (widget.onTracksChanged != null) {
            final converted = updated.map((t) => {
              'path': t['path']?.toString() ?? '',
              'name': t['name']?.toString() ?? '',
            }).toList();
            widget.onTracksChanged!(converted);
          }
        },
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
            Icon(Icons.delete_outline_rounded, color: Color(0xFFF87171), size: 22),
            SizedBox(width: 8),
            Text('Delete Voice Note', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Text('Remove this voice note from the note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF87171)),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onDelete != null) {
                widget.onDelete!();
              }
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
      return const SizedBox(
        height: 50,
        child: Center(child: Text('No tracks', style: TextStyle(color: Colors.grey))),
      );
    }

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final readOnly = widget.onLayoutChanged == null;
    final playerWidget = _buildLayoutWidget(tracks, isDark, theme, progress);

    if (readOnly) {
      return playerWidget;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _showSettings = true),
      onExit: (_) => setState(() => _showSettings = false),
      child: GestureDetector(
        onTap: () => setState(() => _showSettings = !_showSettings),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: playerWidget,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _showSettings = !_showSettings),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Icon(
                          _showSettings ? Icons.close_rounded : Icons.tune_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedOpacity(
              opacity: _showSettings ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(top: _showSettings ? 6 : 0),
                height: _showSettings ? 40 : 0,
                child: _showSettings ? _buildControlBar(theme, isDark) : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutWidget(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    switch (widget.layout) {
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

  // ── Classic Layout ─────────────────────────────────────────────────────────
  Widget _buildClassicLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    final trackName = tracks[_activeTrackIndex]['name'] ?? 'Track';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D1F5E), const Color(0xFF1E1A30)]
              : [const Color(0xFFF0EBFF), const Color(0xFFE8F4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(maxWidth: 36, maxHeight: 36),
                  ),
                ),
                const SizedBox(width: 10),
                if (_isPlaying)
                  _buildVisualizerWave()
                else
                  _buildStaticWave(isDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.mic_rounded, size: 11, color: Color(0xFF8B5CF6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              trackName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF3D1F8A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF7C5ABF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildSliderTrack(progress, isDark),
          ],
        ),
      ),
    );
  }

  // ── Pill Layout ────────────────────────────────────────────────────────────
  Widget _buildPillLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    final trackName = tracks[_activeTrackIndex]['name'] ?? 'Track';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
          children: [
            Row(
              children: [
                InkWell(
                  onTap: _togglePlay,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8B5CF6),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 12,
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
                          fontSize: 10,
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
                          fontSize: 8,
                          fontFamily: 'Inter',
                          color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF7C5ABF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isPlaying)
                  _buildVisualizerWave(bars: 3)
                else
                  _buildStaticWave(isDark, bars: 3),
              ],
            ),
            const SizedBox(height: 4),
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

  // ── Vinyl Layout ───────────────────────────────────────────────────────────
  Widget _buildVinylLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    final trackName = tracks[_activeTrackIndex]['name'] ?? 'Track';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161420) : const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2749) : const Color(0xFFE4DFEB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildVinylRecord(isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trackName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Track: ${_formatDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    InkWell(
                      onTap: _togglePlay,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF111115),
          border: Border.all(color: Colors.white12, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
            ),
            Container(
              width: 22,
              height: 22,
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
                width: 4,
                height: 4,
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

  // ── Playlist Folder Layout ─────────────────────────────────────────────────
  Widget _buildPlaylistLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    final totalTracks = tracks.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B182B) : const Color(0xFFF7F5FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF32284C) : const Color(0xFFE6DFFF),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _playlistExpanded = !_playlistExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C244C) : const Color(0xFFECE5FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_shared_rounded,
                      size: 24,
                      color: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Playlist / Folder',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$totalTracks tracks',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.hintColor),
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
          if (_playlistExpanded) ...[
            const Divider(height: 1),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final trackName = track['name'] ?? 'Track';
                final isActive = index == _activeTrackIndex;

                return InkWell(
                  onTap: () => _selectTrack(index, autoPlay: true),
                  child: Container(
                    color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: isActive && _isPlaying
                              ? _buildVisualizerWave(bars: 3)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isActive ? theme.colorScheme.primary : Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            trackName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          if (_isPlaying || _position != Duration.zero) ...[
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231F35) : const Color(0xFFEFEBFA),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 18),
                        onPressed: _activeTrackIndex > 0 ? () => _selectTrack(_activeTrackIndex - 1, autoPlay: true) : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: _togglePlay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 18),
                        onPressed: _activeTrackIndex < tracks.length - 1 ? () => _selectTrack(_activeTrackIndex + 1, autoPlay: true) : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tracks[_activeTrackIndex]['name'] ?? 'Track',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                              style: const TextStyle(fontSize: 8, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _buildSliderTrack(progress, isDark, height: 2.5),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Cassette Carousel Layout ───────────────────────────────────────────────
  Widget _buildCarouselLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: tracks.length,
            onPageChanged: (idx) => _selectTrack(idx),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final trackName = track['name'] ?? 'Track';
              final isActive = index == _activeTrackIndex;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildCassetteCard(trackName, isDark, isActive, progress),
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                tracks.length,
                (idx) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  width: _activeTrackIndex == idx ? 12.0 : 6.0,
                  height: 6.0,
                  decoration: BoxDecoration(
                    color: _activeTrackIndex == idx ? theme.colorScheme.primary : Colors.grey,
                    borderRadius: BorderRadius.circular(3),
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
  Widget _buildCollageLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    final activeTrack = tracks[_activeTrackIndex];
    final trackName = activeTrack['name'] ?? 'Track';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF211E2E) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 15,
                child: _buildVinylRecord(isDark),
              ),
              Positioned(
                right: 15,
                left: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trackName,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            size: 30,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: _togglePlay,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        _buildVisualizerWave(bars: 3),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (tracks.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                final name = track['name'] ?? 'Track';
                final isActive = index == _activeTrackIndex;

                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: InkWell(
                    onTap: () => _selectTrack(index, autoPlay: true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : (isDark ? const Color(0xFF181524) : Colors.grey.shade50),
                        border: Border.all(
                          color: isActive ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
  Widget _buildGridLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 70,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        final name = track['name'] ?? 'Track';
        final isActive = index == _activeTrackIndex;

        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B192A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : (isDark ? Colors.white12 : Colors.grey.shade200),
            ),
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
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive && _isPlaying ? Colors.redAccent : theme.colorScheme.primary,
                  ),
                  child: Icon(
                    isActive && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isActive)
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(fontSize: 8, color: theme.colorScheme.primary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Stack Deck Layout ──────────────────────────────────────────────────────
  Widget _buildDeckLayout(List<Map<String, String>> tracks, bool isDark, ThemeData theme, double progress) {
    if (tracks.isEmpty) return const SizedBox.shrink();

    return Center(
      child: SizedBox(
        height: 210,
        width: 300,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List.generate(tracks.length, (idx) {
            final offset = (idx - _deckIndex) % tracks.length;
            final isTop = offset == tracks.length - 1;
            final angle = isTop ? 0.0 : ((idx * 6) % 10 - 5) * (math.pi / 180.0);
            final track = tracks[idx];
            final trackName = track['name'] ?? 'Track';
            final isActive = idx == _activeTrackIndex;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: isTop ? 0 : 8.0 * (tracks.length - 1 - offset),
              child: Transform.rotate(
                angle: angle,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _deckIndex = (_deckIndex + 1) % tracks.length;
                      _selectTrack(_deckIndex);
                    });
                  },
                  onDoubleTap: _togglePlay,
                  child: _buildCassetteCard(trackName, isDark, isActive, progress),
                ),
              ),
            );
          }).reversed.toList(),
        ),
      ),
    );
  }

  // ── Cassette Component ─────────────────────────────────────────────────────
  Widget _buildCassetteCard(String name, bool isDark, bool isActive, double progress) {
    final bgColor = isDark ? const Color(0xFF222026) : const Color(0xFFEFECE5);
    final labelColor = isDark ? const Color(0xFF302E36) : Colors.white;
    final labelTextColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      width: 230,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                name.isEmpty ? 'Voice Tape' : name,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: labelTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSprocket(isActive),
                Container(
                  width: 20,
                  height: 2,
                  color: Colors.grey.shade800,
                ),
                _buildSprocket(isActive),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.circle, size: 4, color: Colors.grey.shade600),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _togglePlay,
                    icon: Icon(
                      isActive && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: const Color(0xFFEC4899),
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  if (isActive)
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    )
                  else
                    const Text(
                      '00:00 / 00:00',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              Icon(Icons.circle, size: 4, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 3),
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
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade800,
          border: Border.all(color: Colors.grey.shade400, width: 1.2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...List.generate(6, (i) {
              final angle = (i * 30) * 3.1415926535 / 180;
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: 1.2,
                  height: 12,
                  color: Colors.grey.shade400,
                ),
              );
            }),
            Container(
              width: 6,
              height: 6,
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
          trackHeight: 1.5,
          activeTrackColor: const Color(0xFFEC4899),
          inactiveTrackColor: Colors.black12,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 5),
        ),
        child: Slider(
          value: _duration.inMilliseconds > 0 ? _position.inMilliseconds.toDouble() : 0.0,
          min: 0.0,
          max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
          onChanged: (val) {
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
          trackHeight: 1.5,
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

  Widget _buildVisualizerWave({int bars = 5}) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(bars, (i) {
            final heights = [10.0, 16.0, 12.0, 18.0, 10.0];
            final offset = (i * 0.2 + _waveController.value) % 1.0;
            final h = heights[i % heights.length] * (0.5 + 0.5 * offset);
            return Container(
              width: 3,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
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
        final heights = [8.0, 12.0, 6.0, 14.0, 8.0];
        return Container(
          width: 3,
          height: heights[i % heights.length],
          margin: const EdgeInsets.symmetric(horizontal: 1),
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
              if (widget.onDelete != null)
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
    final active = widget.layout == type;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          if (widget.onLayoutChanged != null) {
            widget.onLayoutChanged!(type);
          }
        },
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
