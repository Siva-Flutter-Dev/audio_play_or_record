import 'package:flutter/cupertino.dart';

/// A custom painter for drawing chat message bubbles.
///
/// Draws a rounded rectangle bubble with a small "tail" pointing
/// to the sender or receiver side.
class BubblePainter extends CustomPainter {
  /// Whether this bubble is sent by the current user.
  final bool isSender;

  /// The color of the bubble.
  final Color color;

  /// Creates a new bubble painter.
  ///
  /// [isSender] determines the direction of the bubble tail.
  /// [color] specifies the bubble's fill color.
  BubblePainter(this.isSender, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    /// Draw the main rounded rectangle bubble
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 6, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(r, paint);

    /// Draw the bubble "tail"
    final path = Path();
    // if (isSender) {
    //   path
    //     ..moveTo(size.width - 6, 20)
    //     ..lineTo(size.width, 25)
    //     ..lineTo(size.width - 6, 30);
    // } else {
    //   path
    //     ..moveTo(6, 20)
    //     ..lineTo(0, 25)
    //     ..lineTo(6, 30);
    // }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) => false;
}
