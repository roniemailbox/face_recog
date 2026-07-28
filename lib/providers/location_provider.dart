import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_point.dart';
import '../services/location_db_service.dart';

class LocationProvider extends ChangeNotifier {
  final _dbService = LocationDbService();

  // ── Titik lokasi tersimpan ──
  List<LocationPoint> _points = [];
  List<LocationPoint> get points => _points;

  // ── Posisi saat ini ──
  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // ── Status GPS ──
  bool _isTracking = false;
  bool get isTracking => _isTracking;
  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;
  String _statusText = 'Menunggu...';
  String get statusText => _statusText;

  // ── Hasil pengecekan radius ──
  LocationPoint? _insidePoint;
  LocationPoint? get insidePoint => _insidePoint;

  StreamSubscription<Position>? _positionStream;

  // ── Load titik lokasi dari database ──
  Future<void> loadPoints() async {
    _points = await _dbService.getAll();
    notifyListeners();
  }

  Future<void> savePoint(LocationPoint point) async {
    await _dbService.save(point);
    await loadPoints();
  }

  Future<void> deletePoint(int id) async {
    await _dbService.delete(id);
    await loadPoints();
  }

  // ── Izin lokasi ──
  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        _statusText = 'Izin lokasi ditolak';
        notifyListeners();
        return false;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      _statusText = 'Izin lokasi ditolak permanen';
      notifyListeners();
      return false;
    }
    _hasPermission = true;
    notifyListeners();
    return true;
  }

  // ── Mulai live tracking ──
  Future<void> startTracking() async {
    if (_isTracking) return;
    final ok = await requestPermission();
    if (!ok) return;

    _isTracking = true;
    _statusText = 'Melacak posisi...';
    notifyListeners();

    // Dapatkan posisi awal
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _checkRadius();
      notifyListeners();
    } catch (_) {}

    // Stream posisi real-time
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (pos) {
        _currentPosition = pos;
        _checkRadius();
        notifyListeners();
      },
      onError: (e) {
        _statusText = 'Gagal melacak: $e';
        _isTracking = false;
        notifyListeners();
      },
    );
  }

  // ── Hentikan tracking ──
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    _currentPosition = null;
    _insidePoint = null;
    _statusText = 'Tracking dihentikan';
    notifyListeners();
  }

  // ── Cek apakah posisi saat ini di dalam radius suatu titik ──
  void _checkRadius() {
    if (_currentPosition == null || _points.isEmpty) {
      _insidePoint = null;
      return;
    }

    LocationPoint? found;
    double closestDist = double.infinity;

    for (final p in _points) {
      final dist = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        p.lat,
        p.lon,
      );
      if (dist <= p.radius && dist < closestDist) {
        closestDist = dist;
        found = p;
      }
    }

    _insidePoint = found;
    if (found != null) {
      _statusText =
          '📍 Di dalam radius: ${found.nama} (${closestDist.toStringAsFixed(0)}m dari pusat)';
    } else if (_points.isNotEmpty) {
      _statusText = '📡 Di luar semua radius';
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
