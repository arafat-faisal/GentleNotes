import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderBottomSheet extends StatefulWidget {
  final String noteId;
  final Function(String filePath) onAttach;

  const VoiceRecorderBottomSheet({
    super.key,
    required this.noteId,
    required this.onAttach,
  });

  @override
  State<VoiceRecorderBottomSheet> createState() => _VoiceRecorderBottomSheetState();
}

class _VoiceRecorderBottomSheetState extends State<VoiceRecorderBottomSheet> with SingleTickerProviderStateMixin {
  // Recorder and Player instances
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  // Recording State
  bool _isRecording = false;
  String? _recordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  // Playback/Preview State
  bool _isPreviewMode = false;
  bool _isPlaying = false;
  Duration _playPosition = Duration.zero;
  Duration _playDuration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _completeSubscription;

  // Animation controller for pulsating recording indicator
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Start recording immediately when bottom sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRecording();
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

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

  Future<void> _startRecording() async {
    try {
      bool hasPerm = false;
      if (kIsWeb) {
        hasPerm = await _audioRecorder.hasPermission();
      } else {
        var status = await Permission.microphone.status;
        if (!status.isGranted) {
          status = await Permission.microphone.request();
        }
        hasPerm = status.isGranted;
      }

      if (hasPerm) {
        String? path;
        RecordConfig config;

        if (kIsWeb) {
          path = '';
          config = const RecordConfig(encoder: AudioEncoder.opus);
        } else {
          final dir = await getTemporaryDirectory();
          path = '${dir.path}/voice_note_${const Uuid().v4()}.m4a';
          config = const RecordConfig(encoder: AudioEncoder.aacLc);
        }

        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordingDuration = Duration.zero;
        });

        await _audioRecorder.start(
          config,
          path: path,
        );

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    final path = await _audioRecorder.stop();
    _recordingTimer?.cancel();
    _pulseController.stop();

    setState(() {
      _isRecording = false;
      if (path != null) {
        _recordingPath = path;
      }
    });

    if (_recordingPath != null) {
      setState(() {
        _isPreviewMode = true;
      });
      _setupPlayerListeners();
    } else {
      if (mounted) Navigator.pop(context);
    }
  }

  void _setupPlayerListeners() {
    _positionSubscription = _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _playPosition = p;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _playDuration = d;
        });
      }
    });

    _completeSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlayback() async {
    final path = _recordingPath;
    if (path == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.play(_getAudioSource(path));
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _discardAndClose() async {
    // Stop recording or playing
    if (_isRecording) {
      await _audioRecorder.stop();
    }
    await _audioPlayer.stop();

    // Delete temp file if exists
    final path = _recordingPath;
    if (!kIsWeb && path != null) {
      final file = io.File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _attachToNote() async {
    final path = _recordingPath;
    if (path == null) return;

    try {
      if (kIsWeb) {
        // Show loading indicator since fetching blob and base64-encoding might take a brief moment
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final base64Str = base64Encode(bytes);
          final dataUrl = 'data:audio/webm;base64,$base64Str';

          if (mounted) {
            Navigator.pop(context); // Close loading indicator
            widget.onAttach(dataUrl);
            Navigator.pop(context); // Close bottom sheet
          }
        } else {
          throw Exception('Failed to load recorded audio blob: ${response.statusCode}');
        }
      } else {
        widget.onAttach(path);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        // Pop loading indicator if open
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save audio recording: $e'), backgroundColor: Colors.red),
        );
      }
    }
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

    final bgColor = isDark ? const Color(0xFF13111C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF252234) : const Color(0xFFE9E6F5);
    final accentColor = theme.colorScheme.primary;

    return WillPopScope(
      onWillPop: () async {
        // Prevent dismissal by back gesture, enforce Discard button click
        await _discardAndClose();
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pull handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D3557) : const Color(0xFFD1CBE8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPreviewMode ? Icons.headphones_rounded : Icons.mic_rounded,
                  color: _isPreviewMode ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isPreviewMode ? 'Preview Voice Note' : 'Recording Voice Note...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Pulsating visualizer OR Audio player seek bar
            if (!_isPreviewMode) ...[
              // RECORDING STATE VIEW
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.6).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Timer Display
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // PREVIEW STATE VIEW
              Row(
                children: [
                  IconButton(
                    iconSize: 40,
                    color: accentColor,
                    icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                    onPressed: _togglePlayback,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Slider(
                          min: 0.0,
                          max: _playDuration.inMilliseconds.toDouble() > 0
                              ? _playDuration.inMilliseconds.toDouble()
                              : 100.0,
                          value: _playPosition.inMilliseconds.toDouble().clamp(
                                0.0,
                                _playDuration.inMilliseconds.toDouble() > 0
                                    ? _playDuration.inMilliseconds.toDouble()
                                    : 100.0,
                              ),
                          onChanged: (value) async {
                            await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_playPosition),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _formatDuration(_playDuration),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 40),

            // Bottom Actions Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _discardAndClose,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isRecording ? _stopRecording : _attachToNote,
                    icon: Icon(_isRecording ? Icons.stop_rounded : Icons.check_circle_rounded),
                    label: Text(_isRecording ? 'Stop' : 'Attach'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.red : accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
