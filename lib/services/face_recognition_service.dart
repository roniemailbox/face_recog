import '../models/face_embedding.dart';
import '../models/registered_face.dart';

/// Matches detected face embeddings against registered faces.
class FaceRecognitionService {
  /// Threshold for Euclidean distance — faces below this are considered a match.
  static const double matchThreshold = 0.25;

  /// Find the best matching registered face for a given embedding.
  /// Returns null if no match is found within the threshold.
  RegisteredFace? findMatch(
    FaceEmbedding embedding,
    List<RegisteredFace> registeredFaces,
  ) {
    if (registeredFaces.isEmpty) return null;

    RegisteredFace? bestMatch;
    double bestDistance = double.infinity;

    for (final face in registeredFaces) {
      final registeredEmbedding = FaceEmbedding(face.embedding);
      final distance = embedding.distanceTo(registeredEmbedding);

      if (distance < bestDistance && distance < matchThreshold) {
        bestDistance = distance;
        bestMatch = face;
      }
    }

    return bestMatch;
  }

  /// Return (match, confidence) for the best match. Confidence is 0–100%.
  (RegisteredFace?, double) findMatchWithConfidence(
    FaceEmbedding embedding,
    List<RegisteredFace> registeredFaces,
  ) {
    if (registeredFaces.isEmpty) return (null, 0);

    RegisteredFace? bestMatch;
    double bestDistance = double.infinity;

    for (final face in registeredFaces) {
      final registeredEmbedding = FaceEmbedding(face.embedding);
      final distance = embedding.distanceTo(registeredEmbedding);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = face;
      }
    }

    if (bestMatch == null) return (null, 0);

    // Convert distance to confidence (0–100%).
    // distance 0.0 → 100%, threshold 0.25 → 0%
    final confidence = ((1 - (bestDistance / matchThreshold)) * 100)
        .clamp(0.0, 100.0);

    return bestDistance < matchThreshold
        ? (bestMatch, confidence)
        : (null, confidence);
  }
}
