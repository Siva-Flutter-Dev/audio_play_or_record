import 'package:flutter/material.dart';
import 'dart:math';
import '../../audio_play_or_record.dart';
import '../controllers/audio_player_controller.dart';
import '../painters/waveform_painter.dart';

class RecordingOverlay extends StatefulWidget {
  final double width;
  final Duration duration;
  final String? audioPath;
  final WaveDirection direction;
  final VoidCallback onDelete;
  final bool showDelete;
  final bool isRecording;

  const RecordingOverlay({
    super.key,
    required this.width,
    required this.duration,
    required this.onDelete,
    this.direction = WaveDirection.left,
    this.showDelete = true,
    this.isRecording = true,
    this.audioPath,
  });

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  final _rand = Random();
  AudioPlayerController? _audioController;

  Duration _position = Duration.zero;
  Duration? _total;
  List<double> _waveformAmplitudes = [];

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    if (!widget.isRecording && widget.audioPath != null) {
      _audioController = AudioPlayerController();
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    await _audioController?.load(widget.audioPath!);

    // TODO: replace this with actual waveform extraction if needed
    _waveformAmplitudes = List.generate(50, (_) => _rand.nextDouble());

    _audioController?.durationStream.listen((d) {
      if (mounted) setState(() => _total = d ?? Duration.zero);
    });

    _audioController?.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    if (!widget.isRecording && widget.audioPath != null) {
      _audioController?.dispose();
    }
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  MainAxisAlignment _align() {
    switch (widget.direction) {
      case WaveDirection.center:
        return MainAxisAlignment.center;
      case WaveDirection.right:
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }

  Widget _wave() {
    if (widget.isRecording) {
      // Random animated waveform
      return LayoutBuilder(
        builder: (_, c) {
          final bars = (c.maxWidth / 6).floor();
          return AnimatedBuilder(
            animation: _waveController,
            builder: (_, _) {
              return Row(
                mainAxisAlignment: _align(),
                children: List.generate(bars, (i) {
                  final h = 6 + _rand.nextInt(18);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      width: 3,
                      height: h.toDouble(),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              );
            },
          );
        },
      );
    } else if (widget.audioPath != null) {
      // Audio-based waveform using your painter
      return CustomPaint(
        painter: WaveformPainter(
          amplitudes: _waveformAmplitudes,
          progress: _total != null
              ? _position.inMilliseconds / _total!.inMilliseconds
              : 0.0,
          active: Colors.greenAccent,
          inactive: Colors.redAccent,
          barWidth: 3,
          spacing: 2,
          barHeightValue: 3
        ),
        size: Size(double.infinity, 3),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _audioController?.isPlaying ?? false;

    return SizedBox(
      width: widget.width,
      height: 56,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            // Delete
            if (widget.showDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),

            // Play / Pause button
            if (!widget.isRecording && widget.audioPath != null)
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (_audioController != null) {
                    isPlaying
                        ? _audioController!.pause()
                        : _audioController!.play();
                  }
                },
              ),

            // Waveform
            Expanded(child: _wave()),

            // Time display
            Text(
              widget.isRecording
                  ? _format(widget.duration)
                  : "${_format(_position)} / ${_format(_total ?? Duration.zero)}",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),

            const SizedBox(width: 6),

            // Mic / Speaker icon
            Icon(
              widget.isRecording ? Icons.mic : Icons.volume_up,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
