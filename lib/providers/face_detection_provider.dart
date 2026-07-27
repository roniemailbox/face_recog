import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_detection_result.dart';
import '../models/registered_face.dart';
import '../services/camera_service.dart';
import '../services/face_database_service.dart';
import '../services/face_detection_service.dart';
import '../services/face_embedding_service.dart';
import '../services/face_recognition_service.dart';

enum AppMode { detect, recognize }

class FaceMatch {
  final int faceId;
  final RegisteredFace? matchedFace;
  final double confidence;
  const FaceMatch({required this.faceId, this.matchedFace, this.confidence = 0});
}

class _SmoothedFace {
  double x, y, width, height;
  _SmoothedFace({required this.x, required this.y, required this.width, required this.height});
}

class FaceDetectionProvider extends ChangeNotifier {
  static const double _smoothingFactor = 0.35;
  static const double recognitionThreshold = 80.0;
  static const Duration _notFoundTimeout = Duration(seconds: 5);

  final CameraService _cameraService = CameraService();
  final FaceDatabaseService _dbService = FaceDatabaseService();
  final FaceEmbeddingService _embeddingService = FaceEmbeddingService();
  final FaceRecognitionService _recognitionService = FaceRecognitionService();
  FaceDetectionService? _faceDetectionService;

  bool _isCameraReady = false;
  bool _isDetecting = false;
  bool _hasPermission = false;
  String _statusMessage = 'Initializing...';
  AppMode _mode = AppMode.detect;
  List<FaceDetectionResult> _faces = [];
  List<FaceMatch> _faceMatches = [];
  List<Face>? _rawFaces;
  final Map<int, _SmoothedFace> _smoothedFaces = {};

  // Recognition state
  String? _recognizedName;
  String? get recognizedName => _recognizedName;
  void clearRecognizedName() => _recognizedName = null;

  bool _notFound = false;
  bool get notFound => _notFound;
  void clearNotFound() => _notFound = false;

  DateTime? _recognizeStartTime;

  // ── Getters ──
  CameraService get camera => _cameraService;
  bool get isCameraReady => _isCameraReady;
  bool get isDetecting => _isDetecting;
  bool get hasPermission => _hasPermission;
  String get statusMessage => _statusMessage;
  AppMode get mode => _mode;
  List<FaceDetectionResult> get faces => _faces;
  List<FaceMatch> get faceMatches => _faceMatches;
  List<RegisteredFace> get registeredFaces => _dbService.getAll();
  int get faceCount => _faces.length;
  int get registeredCount => _dbService.count;

  /// Highest confidence among all current face matches, or null.
  double? get highestConfidence {
    if (_faceMatches.isEmpty) return null;
    double best = 0;
    for (final m in _faceMatches) {
      if (m.confidence > best) best = m.confidence;
    }
    return best > 0 ? best : null;
  }

  Future<void> initialize() async {
    _setStatus('Initializing...');
    try {
      await _dbService.initialize();
      await _cameraService.initialize();
      _hasPermission = true;
      await _cameraService.startCamera();
      _faceDetectionService = FaceDetectionService(onFacesDetected: _onFacesDetected);
      _faceDetectionService!.start(_cameraService.controller!);
      _isCameraReady = true;
      _setStatus(_faces.isEmpty ? 'No face detected' : 'Face detected');
    } catch (e) {
      _setStatus('Error: ${e.toString()}');
    }
  }

  void _onFacesDetected(List<FaceDetectionResult> results, List<Face> rawFaces) {
    final smoothed = <FaceDetectionResult>[];
    for (final face in results) {
      final prev = _smoothedFaces[face.faceId];
      if (prev != null) {
        prev.x += _smoothingFactor * (face.x - prev.x);
        prev.y += _smoothingFactor * (face.y - prev.y);
        prev.width += _smoothingFactor * (face.width - prev.width);
        prev.height += _smoothingFactor * (face.height - prev.height);
        smoothed.add(FaceDetectionResult(
          faceId: face.faceId, x: prev.x, y: prev.y,
          width: prev.width, height: prev.height,
          headEulerAngleY: face.headEulerAngleY,
          headEulerAngleZ: face.headEulerAngleZ,
          smilingProbability: face.smilingProbability,
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
        ));
      } else {
        _smoothedFaces[face.faceId] = _SmoothedFace(x: face.x, y: face.y, width: face.width, height: face.height);
        smoothed.add(face);
      }
    }
    _smoothedFaces.removeWhere((id, _) => !results.any((f) => f.faceId == id));
    _faces = smoothed;
    _rawFaces = rawFaces;
    _isDetecting = results.isNotEmpty;

    if (_mode == AppMode.recognize && results.isNotEmpty) {
      _runRecognition(rawFaces);
    } else if (_mode == AppMode.detect) {
      _faceMatches = [];
      _recognizedName = null;
      _notFound = false;
      _recognizeStartTime = null;
      _setStatus(results.isEmpty ? 'No face detected' : 'Face detected');
    }
    notifyListeners();
  }

  void _runRecognition(List<Face> rawFaces) {
    final registered = _dbService.getAll();
    final matches = <FaceMatch>[];
    for (int i = 0; i < rawFaces.length; i++) {
      final embedding = _embeddingService.extract(rawFaces[i]);
      if (embedding == null) {
        matches.add(FaceMatch(faceId: _faces[i].faceId));
        continue;
      }
      final (match, confidence) = _recognitionService.findMatchWithConfidence(embedding, registered);
      matches.add(FaceMatch(faceId: _faces[i].faceId, matchedFace: match, confidence: confidence));
    }
    _faceMatches = matches;

    // Check >80% match
    bool found = false;
    for (final m in matches) {
      if (m.matchedFace != null && m.confidence >= recognitionThreshold) {
        _recognizedName = m.matchedFace!.name;
        _notFound = false;
        _recognizeStartTime = null;
        found = true;
        break;
      }
    }

    // 5-second timeout: if started and still no match
    if (!found && registered.isNotEmpty) {
      _recognizeStartTime ??= DateTime.now();
      if (DateTime.now().difference(_recognizeStartTime!) >= _notFoundTimeout) {
        _notFound = true;
        _recognizedName = null;
        _recognizeStartTime = null;
      }
    }

    final recognized = matches.where((m) => m.matchedFace != null).length;
    if (found) {
      _setStatus('$_recognizedName dikenali');
    } else if (recognized > 0) {
      _setStatus('$recognized wajah (confidence rendah)');
    } else if (registered.isEmpty) {
      _setStatus('Belum ada data wajah');
    } else {
      _setStatus('Mencari...');
    }
  }

  void setMode(AppMode newMode) {
    _mode = newMode;
    _faceMatches = [];
    _recognizedName = null;
    _notFound = false;
    _recognizeStartTime = null;
    notifyListeners();
  }

  void toggleMode() {
    _mode = _mode == AppMode.detect ? AppMode.recognize : AppMode.detect;
    _faceMatches = [];
    _recognizedName = null;
    _notFound = false;
    _recognizeStartTime = null;
    notifyListeners();
  }

  Future<String?> registerCurrentFace(String name) async {
    if (_rawFaces == null) return 'Kamera belum mendeteksi wajah. Arahkan wajah ke kamera.';
    if (_rawFaces!.isEmpty) return 'Tidak ada wajah terdeteksi.';
    if (_rawFaces!.length > 1) return 'Terlalu banyak wajah (${_rawFaces!.length}). Pastikan hanya 1.';
    final face = _rawFaces!.first;
    final embedding = _embeddingService.extract(face);
    if (embedding == null) {
      final missing = <String>[];
      if (face.landmarks[FaceLandmarkType.leftEye] == null) missing.add('mata kiri');
      if (face.landmarks[FaceLandmarkType.rightEye] == null) missing.add('mata kanan');
      if (face.landmarks[FaceLandmarkType.noseBase] == null) missing.add('hidung');
      if (face.landmarks[FaceLandmarkType.leftMouth] == null) missing.add('mulut kiri');
      if (face.landmarks[FaceLandmarkType.rightMouth] == null) missing.add('mulut kanan');
      if (missing.isNotEmpty) return 'Landmark tidak lengkap: ${missing.join(", ")}. Hadapkan wajah lurus.';
      return 'Gagal ekstrak fitur. Coba dengan pencahayaan lebih baik.';
    }
    try {
      await _dbService.register(name: name, embedding: embedding.values);
      notifyListeners();
      return null;
    } catch (e) {
      return 'Gagal menyimpan: ${e.toString()}';
    }
  }

  Future<void> deleteRegisteredFace(String id) async {
    await _dbService.delete(id);
    notifyListeners();
  }

  void _setStatus(String msg) { _statusMessage = msg; }

  @override
  void dispose() {
    _faceDetectionService?.dispose();
    _cameraService.dispose();
    _dbService.dispose();
    super.dispose();
  }
}
