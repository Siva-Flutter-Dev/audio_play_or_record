import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/audio_record_controller.dart';
import '../recording/recording_overlay.dart';

class RecordMicButton extends StatefulWidget {
  final bool hasMicPermission;
  final Function(String path) onRecorded;

  const RecordMicButton({super.key, required this.onRecorded, this.hasMicPermission=false});

  @override
  State<RecordMicButton> createState() => _RecordMicButtonState();
}

class _RecordMicButtonState extends State<RecordMicButton> {
  final _recorder = AudioRecorderController();

  Offset _start = Offset.zero;
  bool _cancelled = false;
  Duration _duration = Duration.zero;
  Timer? _timer;

  Future<void> _startRecording(LongPressStartDetails d) async {
    if (!widget.hasMicPermission) {
      debugPrint("Mic permission not granted");
      return;
    }

    _start = d.globalPosition;
    _cancelled = false;
    _duration = Duration.zero;

    await _recorder.start();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;

    if (_cancelled) {
      await _recorder.cancel();
      return;
    }

    final path = await _recorder.stop();
    if (path != null && mounted) {
      widget.onRecorded(path);
    }
  }

  void _update(LongPressMoveUpdateDetails d) {
    if (_start.dx - d.globalPosition.dx > 80) {
      if (!_cancelled) {
        setState(() => _cancelled = true);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _startRecording,
      onLongPressMoveUpdate: _update,
      onLongPressEnd: (_) => _stopRecording(),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green,
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          if (_timer != null)
            Positioned(
              top: -70,
              child: RecordingOverlay(
                duration: _duration,
                waveColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
