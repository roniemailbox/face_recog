import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_detection_result.dart';

/// Callback signature: (mapped results, raw ML Kit faces).
typedef FacesDetectedCallback = void Function(
  List<FaceDetectionResult> results,
  List<Face> rawFaces,
);

/// Processes camera frames and detects faces using Google ML Kit.
class FaceDetectionService {
  final FaceDetector _faceDetector;
  bool _isProcessing = false;

  final FacesDetectedCallback onFacesDetected;

  FaceDetectionService({required this.onFacesDetected})
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableClassification: true,
            enableLandmarks: true,
            enableTracking: true,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  void start(CameraController cameraController) {
    cameraController.startImageStream(_processImage);
  }

  Future<void> _processImage(CameraImage cameraImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final inputImage = _buildInputImage(cameraImage);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    try {
      final faces = await _faceDetector.processImage(inputImage);
      final results = faces.map((face) {
        final rect = face.boundingBox;
        return FaceDetectionResult(
          faceId: face.trackingId ?? 0,
          x: rect.left.toDouble(),
          y: rect.top.toDouble(),
          width: rect.width.toDouble(),
          height: rect.height.toDouble(),
          headEulerAngleY: face.headEulerAngleY,
          headEulerAngleZ: face.headEulerAngleZ,
          smilingProbability: face.smilingProbability,
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
        );
      }).toList();

      onFacesDetected(results, faces);
    } catch (_) {
      // Frame skipped.
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final formatGroup = image.format.group;
    final InputImageRotation rotation;
    final InputImageFormat inputFormat;

    switch (formatGroup) {
      case ImageFormatGroup.nv21:
        rotation = InputImageRotation.rotation270deg;
        inputFormat = InputImageFormat.nv21;
      case ImageFormatGroup.bgra8888:
        rotation = InputImageRotation.rotation0deg;
        inputFormat = InputImageFormat.bgra8888;
      default:
        return null;
    }

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputFormat,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
