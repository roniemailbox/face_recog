import 'package:flutter/material.dart';

/// Draws a centered oval guide to help users position their face.
class FaceGuideOverlay extends StatelessWidget {
  final bool showGuide;

  const FaceGuideOverlay({super.key, this.showGuide = true});

  @override
  Widget build(BuildContext context) {
    if (!showGuide) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _GuidePainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ovalWidth = size.width * 0.55;
    final ovalHeight = size.height * 0.38;

    final rect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(ovalHeight / 2),
    );

    // Semi-transparent dark overlay outside the guide.
    final outerPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;

    // Draw outer dark area by drawing full screen minus the oval.
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()..addRRect(rrect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, ovalPath),
      outerPaint,
    );

    // Guide border — dashed effect using white strokes.
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(rrect, borderPaint);

    // Corner accents (like face detection corners).
    final accentPaint = Paint()
      ..color = Colors.teal.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final cornerLen = 30.0;
    _drawCornerAccent(canvas, accentPaint, rrect.left, rrect.top, cornerLen, true, true);
    _drawCornerAccent(canvas, accentPaint, rrect.right, rrect.top, cornerLen, false, true);
    _drawCornerAccent(canvas, accentPaint, rrect.left, rrect.bottom, cornerLen, true, false);
    _drawCornerAccent(canvas, accentPaint, rrect.right, rrect.bottom, cornerLen, false, false);

    // "Posisikan wajah di sini" text.
    final tp = TextPainter(
      text: TextSpan(
        text: 'Posisikan wajah di sini',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, rrect.top - 32),
    );
  }

  void _drawCornerAccent(
    Canvas canvas,
    Paint paint,
    double x,
    double y,
    double len,
    bool isLeft,
    bool isTop,
  ) {
    final dx = isLeft ? 1.0 : -1.0;
    final dy = isTop ? 1.0 : -1.0;
    final path = Path();
    path.moveTo(x, y + dy * len);
    path.lineTo(x, y);
    path.lineTo(x + dx * len, y);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
