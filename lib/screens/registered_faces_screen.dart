import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/face_detection_provider.dart';

class RegisteredFacesScreen extends StatelessWidget {
  const RegisteredFacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Wajah Terdaftar', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<FaceDetectionProvider>(
        builder: (context, p, _) {
          final faces = p.registeredFaces;
          if (faces.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                  child: const Icon(Icons.face_retouching_off, size: 40, color: Colors.white24),
                ),
                const SizedBox(height: 20),
                const Text('Belum ada wajah terdaftar', style: TextStyle(color: Colors.white54, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Gunakan tombol Register untuk menambahkan', style: TextStyle(color: Colors.white24, fontSize: 13)),
              ]),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            itemCount: faces.length,
            itemBuilder: (ctx, i) {
              final f = faces[i];
              final colors = [const Color(0xFF1E3A5F), const Color(0xFF16213E), const Color(0xFF0F3460)];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colors[i % 3], colors[(i + 1) % 3].withValues(alpha: 0.6)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_fmt(f.registeredAt), style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, p, f.id, f.name),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
                        child: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                      ),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  void _confirmDelete(BuildContext ctx, FaceDetectionProvider p, String id, String name) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Wajah', style: TextStyle(color: Colors.white)),
        content: Text('Yakin hapus "$name"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () { p.deleteRegisteredFace(id); Navigator.pop(c); }, child: const Text('Hapus', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}
