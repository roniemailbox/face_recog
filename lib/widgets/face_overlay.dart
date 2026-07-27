import 'package:flutter/material.dart';
import '../models/face_detection_result.dart';
import '../providers/face_detection_provider.dart';

/// Subtle overlay showing recognized face names (no bounding boxes).
class FaceOverlay extends StatelessWidget {
  final List<FaceDetectionResult> faces;
  final Size previewSize;
  final List<FaceMatch>? matches;

  const FaceOverlay({super.key, required this.faces, required this.previewSize, this.matches});

  @override
  Widget build(BuildContext context) {
    if (faces.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _FacePainter(faces: faces, previewSize: previewSize, matches: matches),
      size: Size.infinite,
    );
  }
}

class _FacePainter extends CustomPainter {
  final List<FaceDetectionResult> faces;
  final Size previewSize;
  final List<FaceMatch>? matches;

  _FacePainter({required this.faces, required this.previewSize, this.matches});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final match = (matches != null && i < matches!.length) ? matches![i] : null;
      final isRecognized = match?.matchedFace != null;
      final conf = match?.confidence ?? 0;

      final scaleX = size.width / previewSize.height;
      final scaleY = size.height / previewSize.width;
      final cx = (face.x + face.width / 2) * scaleX;
      final top = face.y * scaleY;

      // Only show label for recognized faces with decent confidence.
      if (!isRecognized && conf < 30) continue;

      final name = isRecognized ? match!.matchedFace!.name : (conf > 0 ? '?' : '');
      if (name.isEmpty) continue;

      // Subtle pill label centered below the face.
      final label = '$name${isRecognized ? "  ${conf.toStringAsFixed(0)}%" : ""}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Draw subtle pill background.
      final pillW = tp.width + 24;
      final pillH = tp.height + 12;
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, top + face.height * scaleY + 24), width: pillW, height: pillH),
        const Radius.circular(20),
      );
      canvas.drawRRect(
        pillRect,
        Paint()..color = (isRecognized ? Colors.green : Colors.grey).withValues(alpha: 0.6),
      );

      tp.paint(canvas, Offset(cx - tp.width / 2, top + face.height * scaleY + 18));
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) => true;
}
