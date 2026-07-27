import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/registered_face.dart';

/// Manages the local database of registered faces using Hive.
class FaceDatabaseService {
  static const String _boxName = 'registered_faces';
  late Box<Map<dynamic, dynamic>> _box;
  final Uuid _uuid = const Uuid();

  Future<void> initialize() async {
    _box = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  /// Register a new face with its embedding.
  Future<RegisteredFace> register({
    required String name,
    required List<double> embedding,
  }) async {
    final face = RegisteredFace(
      id: _uuid.v4(),
      name: name,
      embedding: embedding,
      registeredAt: DateTime.now(),
    );
    await _box.put(face.id, face.toJson());
    return face;
  }

  /// Get all registered faces.
  List<RegisteredFace> getAll() {
    return _box.values.map((json) => RegisteredFace.fromJson(
          Map<String, dynamic>.from(json),
        )).toList();
  }

  /// Delete a registered face by ID.
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Check if any faces are registered.
  bool get isEmpty => _box.isEmpty;
  int get count => _box.length;

  Future<void> dispose() async {
    await _box.close();
  }
}
