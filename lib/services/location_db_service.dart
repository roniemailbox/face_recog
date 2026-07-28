import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_point.dart';

/// Manages local SQLite database for location-radius checkpoints.
class LocationDbService {
  static final LocationDbService _instance = LocationDbService._();
  factory LocationDbService() => _instance;
  LocationDbService._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'location_radius.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE location_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            radius REAL NOT NULL
          )
        ''');
      },
    );
  }

  /// Simpan titik lokasi baru atau update yang sudah ada.
  Future<int> save(LocationPoint point) async {
    final db = await database;
    if (point.id != null) {
      return db.update('location_points', point.toMap(),
          where: 'id = ?', whereArgs: [point.id]);
    }
    return db.insert('location_points', point.toMap());
  }

  /// Ambil semua titik lokasi tersimpan.
  Future<List<LocationPoint>> getAll() async {
    final db = await database;
    final rows = await db.query('location_points');
    return rows.map((r) => LocationPoint.fromMap(r)).toList();
  }

  /// Hapus titik lokasi berdasarkan ID.
  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('location_points', where: 'id = ?', whereArgs: [id]);
  }
}
