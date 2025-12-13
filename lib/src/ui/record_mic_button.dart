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

  const RecordMicButton({
    super.key,
    required this.onRecorded,
    required this.hasMicPermission,
    this.config = const RecordButtonConfig(),
    this.overlayWidth,
  });

  @override
  State<RecordMicButton> createState() => _RecordMicButtonState();
}


class _RecordMicButtonState extends State<RecordMicButton> {
  final _recorder = AudioRecorderController();

  RecordState _state = RecordState.idle;
  Offset _start = Offset.zero;
  Duration _duration = Duration.zero;
  Timer? _timer;

  void _haptic() {
    if (widget.config.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }

  // ---------- START ----------
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

  // ---------- TAP START ----------
  Future<void> _tapStart() async {
    if (!widget.config.enableTapRecord || _state != RecordState.idle) return;
    await _startRecord(LongPressStartDetails(globalPosition: Offset.zero));
  }

  // ---------- MOVE ----------
  void _update(LongPressMoveUpdateDetails d) {
    final dx = _start.dx - d.globalPosition.dx;
    final dy = _start.dy - d.globalPosition.dy;

    // ❌ Slide left to cancel
    if (dx > 80 && _state == RecordState.recording) {
      _cancel();
    }

    // 🔒 Slide up to lock (optional, no icon)
    if (widget.config.enableLock &&
        dy > 60 &&
        _state == RecordState.recording) {
      _haptic();
      setState(() => _state = RecordState.locked);
    }
  }

  // ---------- STOP ----------
  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    if (path != null && mounted) widget.onRecorded(path);

    setState(() => _state = RecordState.idle);
  }

  // ---------- CANCEL ----------
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 70,
      child: Stack(
        alignment: widget.config.micAlignment,
        children: [
          // 🎚 RECORD OVERLAY
          if (_state != RecordState.idle)
            Positioned(
              top: 0,
              child: RecordingOverlay(
                width: widget.overlayWidth??MediaQuery.of(context).size.width * 0.92,
                duration: _duration,
                direction: widget.config.waveDirection,
                showDelete: true,
                isRecording: true,
                onDelete: _cancel,
              ),
            ),

          // 🎤 MIC BUTTON
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _tapStart,
              onLongPressStart: _startRecord,
              onLongPressMoveUpdate: _update,
              onLongPressEnd: (_) {
                if (_state == RecordState.recording) _stop();
              },
              child: CircleAvatar(
                radius: 30,
                backgroundColor:
                _state == RecordState.idle ? Colors.green : Colors.red,
                child: Icon(
                  _state == RecordState.idle ? Icons.mic : Icons.stop,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

