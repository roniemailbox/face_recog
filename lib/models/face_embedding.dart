import 'dart:math';

/// Feature vector extracted from facial landmarks for face matching.
class FaceEmbedding {
  final List<double> values;

  const FaceEmbedding(this.values);

  /// Compute Euclidean distance between two embeddings.
  /// Lower distance = more similar faces.
  double distanceTo(FaceEmbedding other) {
    if (values.length != other.values.length) return double.infinity;
    double sum = 0;
    for (int i = 0; i < values.length; i++) {
      final diff = values[i] - other.values[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  /// Cosine similarity (1.0 = identical, -1.0 = opposite).
  double cosineSimilarity(FaceEmbedding other) {
    if (values.length != other.values.length) return 0;
    double dot = 0, magA = 0, magB = 0;
    for (int i = 0; i < values.length; i++) {
      dot += values[i] * other.values[i];
      magA += values[i] * values[i];
      magB += other.values[i] * other.values[i];
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (sqrt(magA) * sqrt(magB));
  }
}
