import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/audio_record_controller.dart';
import '../recording/recording_overlay.dart';
import 'package:flutter/services.dart';

enum RecordState { idle, recording, locked }

class RecordMicButton extends StatefulWidget {
  final bool hasMicPermission;
  final bool enableHaptics;
  final bool enableLock;
  final Function(String path) onRecorded;

  const RecordMicButton({
    super.key,
    required this.onRecorded,
    this.hasMicPermission = false,
    this.enableHaptics = false,
    this.enableLock = false,
  });

  @override
  State<RecordMicButton> createState() => _RecordMicButtonState();
}

class _RecordMicButtonState extends State<RecordMicButton> {
  final AudioRecorderController _recorder = AudioRecorderController();

  RecordState _state = RecordState.idle;
  Offset _start = Offset.zero;
  Duration _duration = Duration.zero;
  Timer? _timer;

  // ---------------- HAPTIC ----------------
  void _haptic() {
    if (widget.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
  }

  // ---------------- START ----------------
  Future<void> _startRecord(LongPressStartDetails d) async {
    if (!widget.hasMicPermission) return;

    _start = d.globalPosition;
    _duration = Duration.zero;

    await _recorder.start();
    _haptic();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration += const Duration(seconds: 1));
    });

    setState(() => _state = RecordState.recording);
  }

  // ---------------- MOVE ----------------
  void _update(LongPressMoveUpdateDetails d) {
    if (_state != RecordState.recording) return;

    final dx = _start.dx - d.globalPosition.dx;
    final dy = _start.dy - d.globalPosition.dy;

    // 🔒 LOCK (OPTIONAL)
    if (widget.enableLock && dy > 60) {
      _haptic();
      setState(() => _state = RecordState.locked);
      return;
    }

    // ❌ CANCEL (SLIDE LEFT)
    if (dx > 80) {
      _cancel();
    }
  }

  // ---------------- STOP & SAVE ----------------
  Future<void> _stopAndSave() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    if (path != null && mounted) {
      widget.onRecorded(path);
    }

    setState(() => _state = RecordState.idle);
  }

  // ---------------- CANCEL ----------------
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
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 140, // fixed → hit-test safe
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 🎤 MIC / STOP BUTTON
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onLongPressStart:
              _state == RecordState.idle ? _startRecord : null,
              onLongPressMoveUpdate: _update,
              onLongPressEnd: (_) {
                if (_state == RecordState.recording) {
                  _stopAndSave();
                }
              },
              onTap:
              _state == RecordState.locked ? _stopAndSave : null,
              child: CircleAvatar(
                radius: 28,
                backgroundColor:
                _state == RecordState.idle ? Colors.green : Colors.red,
                child: Icon(
                  _state == RecordState.idle
                      ? Icons.mic
                      : Icons.stop,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 🎚 RECORDING OVERLAY
          if (_state != RecordState.idle)
            Positioned(
              top: 0,
              child: SizedBox(
                width: screenWidth * 0.9,
                height: 56,
                child: RecordingOverlay(
                  duration: _duration,
                  isLocked:
                  widget.enableLock && _state == RecordState.locked,
                  onDelete: _cancel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
