import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecordingWave extends StatelessWidget {
  final Color color;

  const RecordingWave({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(18, (i) {
        return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: Random().nextInt(30) + 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .scaleY(
              duration: 500.ms,
              curve: Curves.easeInOut,
              begin: 0.3,
              end: 1,
            );
      }),
    );
  }
}
