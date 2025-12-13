import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/audio_record_controller.dart';
import '../models/record_button_config.dart';
import '../recording/recording_overlay.dart';
import 'package:flutter/services.dart';

class RecordMicButton extends StatefulWidget {
  final bool hasMicPermission;
  final double? overlayWidth;
  final RecordButtonConfig config;
  final Function(String path) onRecorded;
  final TextEditingController? textController;
  final InputDecoration? textFieldDecoration;
  final Widget? micIcon;
  final Widget? stopIcon;
  final Widget? sendIcon;
  final double? buttonRadius; // size of the circle
  final Color? micColor;
  final Color? stopColor;
  final Color? sendColor;
  final EdgeInsets? buttonPadding;

  const RecordMicButton({
    super.key,
    required this.onRecorded,
    required this.hasMicPermission,
    this.config = const RecordButtonConfig(),
    this.overlayWidth,
    this.textController,
    this.textFieldDecoration,
    this.micIcon,
    this.stopIcon,
    this.sendIcon,
    this.buttonRadius,
    this.micColor,
    this.stopColor,
    this.sendColor,
    this.buttonPadding,
  });

  @override
  State<RecordMicButton> createState() => _RecordMicButtonState();
}

class _RecordMicButtonState extends State<RecordMicButton> {
  final _recorder = AudioRecorderController();
  late final TextEditingController _controller;

  RecordState _state = RecordState.idle;
  Offset _start = Offset.zero;
  Duration _duration = Duration.zero;
  Timer? _timer;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _controller = widget.textController ?? TextEditingController();
    _controller.addListener(() => setState(() {}));
  }

  void _haptic() {
    if (widget.config.enableHaptics) HapticFeedback.mediumImpact();
  }

  // ---------- RECORD ----------
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

  Future<void> _tapStart() async {
    if (!widget.config.enableTapRecord || _state != RecordState.idle) return;
    await _startRecord(LongPressStartDetails(globalPosition: Offset.zero));
  }

  void _update(LongPressMoveUpdateDetails d) {
    final dx = _start.dx - d.globalPosition.dx;
    final dy = _start.dy - d.globalPosition.dy;

    if (dx > 80 && _state == RecordState.recording) _cancel();
    if (widget.config.enableLock && dy > 60 && _state == RecordState.recording) {
      _haptic();
      setState(() => _state = RecordState.locked);
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    if (path != null && mounted) {
      setState(() {
        _audioPath = path;
        _state = RecordState.idle;
      });
      widget.onRecorded(path);
    } else {
      setState(() => _state = RecordState.idle);
    }
  }

  Future<void> _cancel() async {
    _haptic();
    _timer?.cancel();
    _timer = null;

    await _recorder.cancel();
    setState(() => _state = RecordState.idle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    if (widget.textController == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showSend = _controller.text.isNotEmpty;

    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: widget.config.micAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _state==RecordState.idle
          // ------------------ CUSTOM TEXTFIELD ------------------
          ?Expanded(
            child: TextField(
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
          )
          // 🎚 RECORD OVERLAY
          :Expanded(
            child: RecordingOverlay(
              width: widget.overlayWidth ?? width * 0.7,
              duration: _duration,
              direction: widget.config.waveDirection,
              showDelete: true,
              audioPath: _audioPath,
              isRecording: _state == RecordState.recording,
              onDelete: _cancel,
            ),
          ),

          const SizedBox(width: 12),

          // 🎤 MIC / STOP / SEND BUTTON
          GestureDetector(
            onTap: showSend
                ? () {
              // Send button tapped
              final text = _controller.text;
              _controller.clear();
              // Optional: pass text to parent via onRecorded or another callback
              widget.onRecorded(text);
            }
                : (_state == RecordState.recording ? _stop : _tapStart),
            onLongPressStart: _startRecord,
            onLongPressMoveUpdate: _update,
            onLongPressEnd: (_) {
              if (_state == RecordState.recording) _stop();
            },
            child: Container(
              width: widget.buttonRadius ?? 60,
              height: widget.buttonRadius ?? 60,
              padding: widget.buttonPadding ?? const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: showSend
                    ? (widget.sendColor ?? Colors.blue)
                    : (_state == RecordState.idle
                    ? (widget.micColor ?? Colors.green)
                    : (widget.stopColor ?? Colors.red)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: showSend
                    ? (widget.sendIcon ?? const Icon(Icons.send, color: Colors.white))
                    : (_state == RecordState.idle
                    ? (widget.micIcon ?? const Icon(Icons.mic, color: Colors.white))
                    : (widget.stopIcon ?? const Icon(Icons.stop, color: Colors.white))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
