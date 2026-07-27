import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/face_detection_provider.dart';

class RegisterFaceScreen extends StatefulWidget {
  const RegisterFaceScreen({super.key});
  @override
  State<RegisterFaceScreen> createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegistering = false;
  bool _success = false;

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isRegistering = true);
    final error = await context.read<FaceDetectionProvider>().registerCurrentFace(name);
    if (!mounted) return;
    if (error == null) {
      setState(() { _isRegistering = false; _success = true; });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _isRegistering = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daftarkan Wajah', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<FaceDetectionProvider>(
        builder: (context, p, _) {
          final faceOk = p.faceCount == 1;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera
              if (p.isCameraReady) _CamView(controller: p.camera.controller!)
              else const Center(child: CircularProgressIndicator(color: Colors.white)),

              // Success overlay
              if (_success)
                Container(color: Colors.black54, child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 80),
                  SizedBox(height: 16),
                  Text('BERHASIL!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Wajah telah didaftarkan', style: TextStyle(color: Colors.white70, fontSize: 15)),
                ]))),

              // Bottom glass panel
              Positioned(bottom: 0, left: 0, right: 0, child: _GlassPanel(faceOk: faceOk, nameCtrl: _nameController, formKey: _formKey, isRegistering: _isRegistering, onRegister: _register, faceCount: p.faceCount)),
            ],
          );
        },
      ),
    );
  }
}

class _CamView extends StatelessWidget {
  final CameraController controller;
  const _CamView({required this.controller});
  @override
  Widget build(BuildContext context) {
    final ps = controller.value.previewSize!;
    return LayoutBuilder(
      builder: (ctx, c) {
        final sr = c.maxWidth / c.maxHeight;
        final cr = ps.height / ps.width;
        final scale = cr > sr ? c.maxHeight / ps.width : c.maxWidth / ps.height;
        return ClipRect(child: Transform.scale(scale: scale, child: Center(child: CameraPreview(controller))));
      },
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final bool faceOk;
  final TextEditingController nameCtrl;
  final GlobalKey<FormState> formKey;
  final bool isRegistering;
  final VoidCallback onRegister;
  final int faceCount;
  const _GlassPanel({required this.faceOk, required this.nameCtrl, required this.formKey, required this.isRegistering, required this.onRegister, required this.faceCount});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 28 + bottom),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          const Color(0xFF1A1A2E).withValues(alpha: 0.85),
          const Color(0xFF0F0F23).withValues(alpha: 0.95),
        ]),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Status indicator
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: faceOk ? Colors.green : Colors.orange)),
            const SizedBox(width: 10),
            Text(faceOk ? 'Wajah terdeteksi — siap didaftarkan' : faceCount == 0 ? 'Arahkan wajah ke kamera...' : 'Pastikan hanya 1 wajah',
              style: TextStyle(color: faceOk ? Colors.greenAccent : Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 20),

          // Name input
          TextFormField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Masukkan nama',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5)),
              prefixIcon: const Icon(Icons.badge_outlined, color: Colors.tealAccent),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 16),

          // Register button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: (isRegistering || !faceOk) ? null : onRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isRegistering
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.fingerprint, size: 22), SizedBox(width: 10),
                      Text('DAFTARKAN WAJAH', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ]),
            ),
          ),
        ]),
      ),
    );
  }
}
