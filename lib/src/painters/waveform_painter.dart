import 'package:flutter/material.dart';

/// A custom painter for rendering audio waveforms.
///
/// Draws a horizontal sequence of bars representing audio amplitudes.
/// Supports highlighting the portion of the waveform that has already played.
class WaveformPainter extends CustomPainter {
  /// List of normalized amplitude values (0.0 to 1.0) for each waveform bar.
  final List<double> amplitudes;

  /// Playback progress as a value between 0.0 and 1.0.
  ///
  /// Bars up to this progress are painted with the [active] color.
  final double progress;

  /// Color of the played portion of the waveform.
  final Color active;

  /// Color of the unplayed portion of the waveform.
  final Color inactive;

  /// Width of each waveform bar.
  final double barWidth;

  /// Space between waveform bars.
  final double spacing;

  /// Creates a new [WaveformPainter].
  ///
  /// All parameters are required.
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
    final centerY = size.height / 2;
    final playedBars = (amplitudes.length * progress).floor();

    final totalWidth = amplitudes.length * (barWidth + spacing) - spacing;
    final startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final paint = Paint()
        ..color = i <= playedBars ? active : inactive
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      final barHeight = amplitudes[i] * size.height;
      final x = startX + i * (barWidth + spacing);

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
