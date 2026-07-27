import 'package:camera/camera.dart';

/// Manages the device camera lifecycle.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isTakingPicture => _controller?.value.isTakingPicture ?? true;

  /// Initialize available cameras (prefer front-facing for face detection).
  Future<void> initialize() async {
    _cameras = await availableCameras();
  }

  /// Start the front camera at medium resolution.
  Future<void> startCamera() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }

    final frontCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller!.initialize();
    // Stream started by FaceDetectionService — do NOT start here.
  }

  /// Take a picture (optional snapshot feature).
  Future<XFile?> takePicture() async {
    if (!isInitialized) return null;
    return _controller!.takePicture();
  }

  Future<void> dispose() async {
    if (_controller != null) {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _controller!.dispose();
      _controller = null;
    }
  }
}
