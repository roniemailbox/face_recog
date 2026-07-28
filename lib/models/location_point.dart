/// Titik lokasi dengan radius untuk pengecekan posisi.
class LocationPoint {
  final int? id;
  final String nama;
  final double lat;
  final double lon;
  final double radius; // dalam meter

  const LocationPoint({
    this.id,
    required this.nama,
    required this.lat,
    required this.lon,
    required this.radius,
  });

  LocationPoint copyWith({
    int? id,
    String? nama,
    double? lat,
    double? lon,
    double? radius,
  }) {
    return LocationPoint(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      radius: radius ?? this.radius,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nama': nama,
        'lat': lat,
        'lon': lon,
        'radius': radius,
      };

  factory LocationPoint.fromMap(Map<String, dynamic> map) => LocationPoint(
        id: map['id'] as int?,
        nama: map['nama'] as String? ?? '',
        lat: (map['lat'] as num).toDouble(),
        lon: (map['lon'] as num).toDouble(),
        radius: (map['radius'] as num).toDouble(),
      );
}
