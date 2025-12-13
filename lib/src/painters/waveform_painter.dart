import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color active;
  final Color inactive;
  final double barWidth;
  final double spacing;

  WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.active,
    required this.inactive,
    required this.barWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final playedBars = (amplitudes.length * progress).floor();
    final centerY = size.height / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final paint = Paint()
        ..color = i <= playedBars ? active : inactive
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      final height = amplitudes[i] * size.height;
      final x = i * (barWidth + spacing);

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
