import 'package:flutter/material.dart';
import 'dart:math';
import '../models/record_button_config.dart';


class RecordingOverlay extends StatefulWidget {
  final double width;
  final Duration duration;
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
  });

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            if (widget.showDelete)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onDelete,
              ),

            // 🌊 WAVE
            Expanded(child: _wave()),

            // ⏱ TIME
            Text(
              _format(widget.duration),
              style: const TextStyle(color: Colors.white),
            ),

            const SizedBox(width: 8),

            // 🎤 / 🔊
            Icon(
              widget.isRecording ? Icons.mic : Icons.volume_up,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _wave() {
    return LayoutBuilder(
      builder: (_, c) {
        final bars = (c.maxWidth / 6).floor();
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
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
                      color: Colors.redAccent,
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

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }
}

