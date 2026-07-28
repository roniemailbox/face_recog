import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/location_point.dart';
import '../providers/location_provider.dart';

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> {
  final _namaCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadPoints();
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  // ── Dialog tambah titik ──
  void _showAddDialog([LocationPoint? existing]) {
    if (existing != null) {
      _namaCtrl.text = existing.nama;
      _latCtrl.text = existing.lat.toString();
      _lonCtrl.text = existing.lon.toString();
      _radiusCtrl.text = existing.radius.toStringAsFixed(0);
    } else {
      _namaCtrl.clear();
      _latCtrl.clear();
      _lonCtrl.clear();
      _radiusCtrl.text = '50';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Titik' : 'Tambah Titik'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nama', hintText: 'contoh: Kantor, Sekolah'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lonCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _radiusCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radius (meter)',
                  suffixText: 'm',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('BATAL')),
          if (existing != null)
            TextButton(
              onPressed: () {
                context.read<LocationProvider>().deletePoint(existing.id!);
                Navigator.pop(ctx);
              },
              child: const Text('HAPUS', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(_latCtrl.text);
              final lon = double.tryParse(_lonCtrl.text);
              final radius = double.tryParse(_radiusCtrl.text);
              if (lat == null || lon == null || radius == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Isi koordinat & radius yang valid')),
                );
                return;
              }
              context.read<LocationProvider>().savePoint(LocationPoint(
                    id: existing?.id,
                    nama: _namaCtrl.text.isEmpty ? 'Titik' : _namaCtrl.text,
                    lat: lat,
                    lon: lon,
                    radius: radius,
                  ));
              Navigator.pop(ctx);
            },
            child: Text(existing != null ? 'UPDATE' : 'SIMPAN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();

    // Default center: Indonesia atau posisi saat ini
    final center = provider.currentPosition != null
        ? LatLng(provider.currentPosition!.latitude,
            provider.currentPosition!.longitude)
        : const LatLng(-6.2088, 106.8456); // Jakarta default

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Radius'),
        actions: [
          IconButton(
            icon: Icon(provider.isTracking ? Icons.stop : Icons.play_arrow),
            tooltip: provider.isTracking ? 'Stop Tracking' : 'Start Tracking',
            onPressed: () {
              if (provider.isTracking) {
                provider.stopTracking();
              } else {
                provider.startTracking();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: 'Tambah titik',
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── MAP ──
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.face_recog',
              ),

              // ── Radius circles ──
              for (final p in provider.points)
                CircleLayer(circles: [
                  CircleMarker(
                    point: LatLng(p.lat, p.lon),
                    radius: p.radius,
                    useRadiusInMeter: true,
                    color: provider.insidePoint?.id == p.id
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.blue.withValues(alpha: 0.15),
                    borderColor: provider.insidePoint?.id == p.id
                        ? Colors.green
                        : Colors.blue,
                    borderStrokeWidth: provider.insidePoint?.id == p.id ? 3 : 1.5,
                  ),
                ]),

              // ── Center point markers ──
              MarkerLayer(markers: [
                for (final p in provider.points)
                  Marker(
                    point: LatLng(p.lat, p.lon),
                    width: 40,
                    height: 40,
                    child: Tooltip(
                      message: '${p.nama}\nRadius: ${p.radius.toStringAsFixed(0)}m',
                      child: Icon(
                        Icons.location_on,
                        color: provider.insidePoint?.id == p.id
                            ? Colors.green
                            : Colors.red,
                        size: 36,
                      ),
                    ),
                  ),

                // ── Posisi saat ini ──
                if (provider.currentPosition != null)
                  Marker(
                    point: LatLng(
                      provider.currentPosition!.latitude,
                      provider.currentPosition!.longitude,
                    ),
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.teal,
                      size: 44,
                    ),
                  ),
              ]),
            ],
          ),

          // ── Status bar ──
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: provider.insidePoint != null
                    ? Colors.green.shade700
                    : Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    provider.isTracking
                        ? Icons.my_location
                        : Icons.location_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.statusText,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── List titik tersimpan ──
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: provider.points.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Belum ada titik. Tekan + untuk tambah.',
                          style: TextStyle(color: Colors.white54)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      shrinkWrap: true,
                      itemCount: provider.points.length,
                      separatorBuilder: (ctx2, idx2) => const Divider(
                          color: Colors.white12, height: 1),
                      itemBuilder: (ctx, i) {
                        final p = provider.points[i];
                        final isInside = provider.insidePoint?.id == p.id;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            isInside ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isInside ? Colors.green : Colors.white38,
                            size: 20,
                          ),
                          title: Text(p.nama,
                              style: TextStyle(
                                color: isInside ? Colors.green : Colors.white,
                                fontWeight:
                                    isInside ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              )),
                          subtitle: Text(
                            '${p.lat.toStringAsFixed(5)}, ${p.lon.toStringAsFixed(5)} • R:${p.radius.toStringAsFixed(0)}m',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.white38,
                            onPressed: () => _showAddDialog(p),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
