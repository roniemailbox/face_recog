import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_embedding.dart';

/// Extracts geometry-based face embeddings from ML Kit landmarks.
///
/// Uses normalized distances between facial landmarks to create a
/// 10-dimensional feature vector suitable for face matching.
class FaceEmbeddingService {
  /// Extract an embedding from a detected face using its landmarks.
  /// Returns null if insufficient landmarks are available.
  FaceEmbedding? extract(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    final noseBase = face.landmarks[FaceLandmarkType.noseBase];
    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];

    if (leftEye == null ||
        rightEye == null ||
        noseBase == null ||
        leftMouth == null ||
        rightMouth == null) {
      return null;
    }

    final rect = face.boundingBox;
    final faceWidth = rect.width.toDouble();
    final faceHeight = rect.height.toDouble();

    if (faceWidth <= 0 || faceHeight <= 0) return null;

    // Convert Point<int> → Point<double>
    Point<double> p(FaceLandmark l) =>
        Point(l.position.x.toDouble(), l.position.y.toDouble());

    final le = p(leftEye);
    final re = p(rightEye);
    final nb = p(noseBase);
    final lm = p(leftMouth);
    final rm = p(rightMouth);

    // Normalize all distances by face dimensions.
    final values = <double>[
      _dist(le, re) / faceWidth,
      _midpoint(le, re).y / faceHeight,
      _dist(nb, _midpoint(lm, rm)) / faceHeight,
      _dist(lm, rm) / faceWidth,
      _dist(le, nb) / faceWidth,
      _dist(re, nb) / faceWidth,
      _dist(le, lm) / faceWidth,
      _dist(re, rm) / faceWidth,
      _angle(le, re),
      faceWidth / faceHeight,
    ];

    return FaceEmbedding(values);
  }

  double _dist(Point<double> a, Point<double> b) =>
      sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));

  Point<double> _midpoint(Point<double> a, Point<double> b) =>
      Point<double>((a.x + b.x) / 2, (a.y + b.y) / 2);

  double _angle(Point<double> leftEye, Point<double> rightEye) =>
      atan2(rightEye.y - leftEye.y, rightEye.x - leftEye.x);
}
