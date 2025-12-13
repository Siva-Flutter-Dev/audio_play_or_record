import 'package:flutter/material.dart';
import 'dart:math';
import '../controllers/audio_player_controller.dart';
import '../models/record_button_config.dart';


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
  late final AudioPlayerController _audioController;

  Duration _position = Duration.zero;
  Duration? _total;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    if (!widget.isRecording && widget.audioPath != null) {
      _audioController = AudioPlayerController();
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    await _audioController.load(widget.audioPath!);

    _audioController.durationStream.listen((d) {
      if (mounted) setState(() => _total = d ?? Duration.zero);
    });

    _audioController.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    if (!widget.isRecording && widget.audioPath != null) {
      _audioController.dispose();
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
    return LayoutBuilder(
      builder: (_, c) {
        final bars = (c.maxWidth / 6).floor();
        final progress = !widget.isRecording && widget.audioPath != null && _total != null
            ? (_position.inMilliseconds / _total!.inMilliseconds)
            .clamp(0.0, 1.0)
            : null;

        return AnimatedBuilder(
          animation: _waveController,
          builder: (_, __) {
            return Row(
              mainAxisAlignment: _align(),
              children: List.generate(bars, (i) {
                final active =
                    progress != null && i / bars <= progress;

                final h = 6 + _rand.nextInt(18);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 3,
                    height: h.toDouble(),
                    decoration: BoxDecoration(
                      color: active ? Colors.greenAccent : Colors.redAccent,
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
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying =
    !widget.isRecording && widget.audioPath != null ;
        // ? _audioController.isPlaying : false;

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
            // 🗑 DELETE
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
            ),

            // ▶ / ⏸ for playback
            if (!widget.isRecording && widget.audioPath != null)
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  isPlaying
                      ? _audioController.pause()
                      : _audioController.play();
                },
              ),

            // 🌊 WAVEFORM
            Expanded(child: _wave()),

            // ⏱ TIME
            Text(
              widget.isRecording
                  ? _format(widget.duration)
                  : "${_format(_position)} / ${_format(_total ?? Duration.zero)}",
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),

            const SizedBox(width: 6),

            // 🎤 / 🔊 ICON
            Icon(
              widget.isRecording
                  ? Icons.mic
                  : Icons.volume_up,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

