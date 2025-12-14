import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../controllers/audio_record_controller.dart';
import '../controllers/audio_player_controller.dart';
import '../models/record_button_config.dart';
import '../painters/waveform_painter.dart';
import 'package:flutter/services.dart';


/// A button widget for recording audio with tap, long-press, or lock-to-record support.
///
/// Displays an animated waveform while recording and can send or delete the
/// recorded audio.
/// A customizable microphone recording button widget with send functionality.
///
/// Supports tap-to-record, long-press recording, waveform animations, and
/// chat-style UI interactions. Can handle both recording and sending audio
/// messages with optional text input integration.
class RecordMicButton extends StatefulWidget {
  /// Whether the app has permission to access the microphone.
  final bool hasMicPermission;

  /// Indicates whether the send button should be enabled.
  final bool isSendEnable;

  /// Optional width of the overlay for recording controls.
  final double? overlayWidth;

  /// Height of the main recording button.
  final double height;

  /// Configuration for recording behavior, haptics, locking, and animations.
  final RecordButtonConfig config;

  /// Callback executed when recording is finished.
  ///
  /// [path] is the path of the recorded audio file.
  final Function(String path) onRecorded;

  /// Callback executed when the send button is pressed.
  final VoidCallback onMessageSend;

  /// Callback executed when the recorded audio is deleted.
  final VoidCallback onDelete;

  /// Optional text controller for an associated input field.
  final TextEditingController? textController;

  /// Optional decoration for the input field.
  final InputDecoration? textFieldDecoration;

  /// Optional custom widget for the mic icon.
  final Widget? micIcon;

  /// Path of the currently recorded audio file.
  final String? audioPath;

  /// Optional custom widget for the stop button.
  final Widget? stopIcon;

  /// Optional custom widget for the send button.
  final Widget? sendIcon;

  /// Radius of the main recording button.
  final double? buttonRadius;

  /// Primary color for the recording button.
  final Color primaryColor;

  /// Color of the stop button when recording.
  final Color stopButtonColor;

  /// Default icon color.
  final Color iconColor;

  /// Icon color while recording.
  final Color iconWhileRecColor;

  /// Color of the running waveform animation.
  final Color runningWave;

  /// Background color of the waveform.
  final Color backgroundWave;

  /// Background color of the audio container.
  final Color backgroundAudio;

  /// Optional padding around the recording button.
  final EdgeInsets? buttonPadding;

  /// Creates a new `RecordMicButton`.
  ///
  /// [hasMicPermission], [onRecorded], [onMessageSend], and [onDelete] are required.
  /// Other parameters are optional and provide customization for appearance and behavior.
  const RecordMicButton({
    super.key,
    required this.onRecorded,
    required this.hasMicPermission,
    required this.onMessageSend,
    required this.onDelete,
    this.isSendEnable = false,
    this.height = 62,
    this.config = const RecordButtonConfig(),
    this.overlayWidth,
    this.textController,
    this.textFieldDecoration,
    this.micIcon,
    this.stopIcon,
    this.sendIcon,
    this.buttonRadius,
    this.primaryColor = Colors.blue,
    this.stopButtonColor = Colors.red,
    this.iconColor = Colors.white,
    this.iconWhileRecColor = Colors.black,
    this.runningWave = Colors.blue,
    this.backgroundWave = Colors.black12,
    this.backgroundAudio = Colors.white,
    this.buttonPadding,
    this.audioPath,
  });

  @override
  State<RecordMicButton> createState() => _RecordMicButtonState();
}

class _RecordMicButtonState extends State<RecordMicButton>
    with SingleTickerProviderStateMixin {
  /// Controller for recording audio.
  final _recorder = AudioRecorderController();

  /// Text controller for the optional input field.
  late final TextEditingController _controller;

  /// Current recording state.
  RecordState _state = RecordState.idle;

  /// Starting position of long press for gesture tracking.
  Offset _start = Offset.zero;

  /// Current recording duration.
  Duration _duration = Duration.zero;

  /// Timer for updating recording duration.
  Timer? _timer;

  /// Audio playback controller.
  AudioPlayerController? _audioController;

  /// Current playback position.
  Duration _position = Duration.zero;

  /// Total duration of the loaded audio.
  Duration? _total;

  /// Waveform amplitudes for playback visualization.
  List<double> _waveformAmplitudes = [];

  /// Random generator for dummy waveform.
  final _rand = Random();

  /// Animation controller for waveform animations.
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // Initialize text controller
    _controller = widget.textController ?? TextEditingController();
    _controller.addListener(() => setState(() {}));

    // Initialize waveform animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // If an initial audio path is provided, initialize audio player
    if (widget.audioPath != null) _initPlayer(widget.audioPath!);
  }

  /// Initializes the audio player and waveform visualization.
  Future<void> _initPlayer(String path) async {
    _audioController?.dispose();
    _audioController = AudioPlayerController();
    await _audioController?.load(path);

    // Dummy waveform generation; can replace with actual extraction
    _waveformAmplitudes = List.generate(50, (_) => _rand.nextDouble());

    // Listen for duration updates
    _audioController?.durationStream.listen((d) {
      if (mounted) setState(() => _total = d ?? Duration.zero);
    });

    // Listen for playback position updates
    _audioController?.positionStream.listen((p) {
      if (mounted) {
        setState(() {
          _position = p;
          if (_total != null &&
              p >= _total! &&
              _audioController!.isPlaying) {
            _audioController?.pause();
            _audioController?.seek(Duration.zero);
            _position = Duration.zero;
          }
        });
      }
    });
  }

  /// Triggers haptic feedback if enabled in configuration.
  void _haptic() {
    if (widget.config.enableHaptics) HapticFeedback.mediumImpact();
  }

  /// Starts recording audio on long press.
  Future<void> _startRecord(LongPressStartDetails d) async {
    if (!widget.hasMicPermission || _state != RecordState.idle) return;
    _start = d.globalPosition;
    _duration = Duration.zero;

    await _recorder.start();
    _haptic();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration += const Duration(seconds: 1));
    });

    setState(() => _state = RecordState.recording);
  }

  /// Starts recording via tap gesture if enabled.
  Future<void> _tapStart() async {
    if (!widget.config.enableTapRecord || _state != RecordState.idle) return;
    await _startRecord(LongPressStartDetails(globalPosition: Offset.zero));
  }

  /// Handles gesture updates for cancel or lock actions.
  void _update(LongPressMoveUpdateDetails d) {
    final dx = _start.dx - d.globalPosition.dx;
    final dy = _start.dy - d.globalPosition.dy;

    // Cancel if swiped left beyond threshold
    if (dx > 80 && _state == RecordState.recording) _cancel();

    // Lock recording if swiped up and locking enabled
    if (widget.config.enableLock && dy > 60 && _state == RecordState.recording) {
      _haptic();
      setState(() => _state = RecordState.locked);
    }
  }

  /// Stops recording and triggers the onRecorded callback.
  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    if (path != null && mounted) {
      setState(() => _state = RecordState.idle);
      widget.onRecorded(path);
      _initPlayer(path); // initialize playback immediately
    } else {
      setState(() => _state = RecordState.idle);
    }
  }

  /// Cancels the recording and triggers the onDelete callback.
  Future<void> _cancel() async {
    _haptic();
    _timer?.cancel();
    _timer = null;

    await _recorder.cancel();
    setState(() {
      widget.onDelete.call();
      _audioController = null;
      _state = RecordState.idle;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _audioController?.dispose();
    if (widget.textController == null) _controller.dispose();
    _waveController.dispose();
    super.dispose();
  }

  /// Formats a [Duration] into `mm:ss` string.
  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Widget _wave() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final barWidth = 3.0;
        final spacing = 2.0;
        final barCount = (availableWidth / (barWidth + spacing)).floor();

        List<double> amplitudes;
        if (_state == RecordState.recording) {
          /// Animated random waveform for recording
          amplitudes = List.generate(barCount, (_) => _rand.nextDouble());
        }
        else if (_audioController != null) {
          /// Playback waveform: use pre-extracted amplitudes
          if (_waveformAmplitudes.isEmpty) {
            amplitudes = List.generate(barCount, (_) => _rand.nextDouble());
          } else {
            /// Resize to fit the available width
            amplitudes = List.generate(barCount, (i) {
              final index = (i * _waveformAmplitudes.length / barCount).floor();
              return _waveformAmplitudes[index.clamp(0, _waveformAmplitudes.length - 1)];
            });
          }
        } else {
          return const SizedBox.shrink();
        }

        if (_state == RecordState.recording) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (_, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: amplitudes.map((amp) {
                  final height = 6 + (amp * 18); // min 6, max 24
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                    child: Container(
                      width: barWidth,
                      height: height,
                      decoration: BoxDecoration(
                        color: widget.runningWave,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        } else {
          // Playback waveform
          return CustomPaint(
            painter: WaveformPainter(
              amplitudes: amplitudes,
              progress: (_total != null && _total!.inMilliseconds > 0)
                  ? (_position.inMilliseconds / _total!.inMilliseconds)
                  : 0.0,
              active: widget.runningWave,
              inactive: widget.backgroundWave,
              barWidth: barWidth,
              spacing: spacing,
            ),
            size: Size(availableWidth, 56),
          );
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showSend = _controller.text.isNotEmpty || widget.isSendEnable;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: widget.config.micAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: (_state != RecordState.idle || _audioController != null)
                ? Container(
              width: widget.overlayWidth ?? width * 0.7,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: widget.backgroundAudio,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  // Delete button
                  IconButton(
                    icon: Icon(CupertinoIcons.delete, color: widget.stopButtonColor),
                    onPressed: _cancel,
                  ),
                  // Play/Pause button
                  if (_audioController != null)
                    IconButton(
                      icon: Icon(
                        _audioController!.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.iconWhileRecColor,
                      ),
                      onPressed: () {
                        if (_audioController != null) {
                          _audioController!.isPlaying
                              ? _audioController!.pause()
                              : _audioController!.play();
                        }
                      },
                    ),
                  Expanded(child: _wave()),
                  Text(
                    _state == RecordState.recording
                        ? _format(_duration)
                        : "${_format(_position)} / ${_format(_total ?? Duration.zero)}",
                    style: TextStyle(color: widget.iconWhileRecColor, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _state == RecordState.recording ? Icons.mic : Icons.volume_up,
                    color: widget.iconWhileRecColor,
                    size: 18,
                  ),
                ],
              ),
            )
                : TextField(
              controller: _controller,
              decoration: widget.textFieldDecoration ??
                  InputDecoration(
                    hintText: 'Type a message',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: showSend
                ? widget.onMessageSend
                : (_state == RecordState.recording ? _stop : _tapStart),
            onLongPressStart: _startRecord,
            onLongPressMoveUpdate: _update,
            onLongPressEnd: (_) {
              if (_state == RecordState.recording) _stop();
            },
            child: Container(
              width: widget.height,
              height: widget.height,
              padding: widget.buttonPadding ?? EdgeInsets.zero,
              decoration: BoxDecoration(
                color: showSend
                    ? (widget.primaryColor)
                    : (_state == RecordState.idle
                    ? (widget.primaryColor)
                    : (widget.stopButtonColor)),
                borderRadius: BorderRadius.circular(widget.buttonRadius??50)
              ),
              child: Center(
                child: showSend
                    ? (widget.sendIcon ?? Icon(Icons.send, color: widget.iconColor))
                    : (_state == RecordState.idle
                    ? (widget.micIcon ?? Icon(Icons.mic, color: widget.iconColor))
                    : (widget.stopIcon ?? Icon(Icons.stop, color: widget.iconColor))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
