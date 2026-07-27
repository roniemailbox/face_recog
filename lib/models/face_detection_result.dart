/// Represents a single detected face with its bounding box and landmarks.
class FaceDetectionResult {
  final int faceId;
  final double x, y, width, height;
  final double? headEulerAngleY; // yaw
  final double? headEulerAngleZ; // roll
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;

  const FaceDetectionResult({
    required this.faceId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
  });

  /// Bounding box relative to image size (0.0–1.0).
  bool get isValid => width > 0 && height > 0;

  @override
  String toString() =>
      'Face #$faceId | smile: ${smilingProbability?.toStringAsFixed(2)} | '
      'yaw: ${headEulerAngleY?.toStringAsFixed(1)}°';
}
