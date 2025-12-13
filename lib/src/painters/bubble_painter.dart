import 'package:flutter/cupertino.dart';

class BubblePainter extends CustomPainter {
  final bool isSender;
  final Color color;

  BubblePainter(this.isSender, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width - 6, size.height),
      const Radius.circular(16),
    );
    canvas.drawRRect(r, paint);

    final path = Path();
    if (isSender) {
      path
        ..moveTo(size.width - 6, 20)
        ..lineTo(size.width, 25)
        ..lineTo(size.width - 6, 30);
    } else {
      path
        ..moveTo(6, 20)
        ..lineTo(0, 25)
        ..lineTo(6, 30);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
