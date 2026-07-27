import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/face_detection_provider.dart';
import '../widgets/face_overlay.dart';
import '../widgets/face_guide_overlay.dart';
import 'register_face_screen.dart';
import 'registered_faces_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final FaceDetectionProvider _provider;
  Timer? _notifTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = context.read<FaceDetectionProvider>();
    _provider.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _provider.initialize();
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _scheduleClear(FaceDetectionProvider p) {
    _notifTimer?.cancel();
    _notifTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        p.clearRecognizedName();
        p.clearNotFound();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<FaceDetectionProvider>(
        builder: (context, p, _) {
          if (p.recognizedName != null || p.notFound) _scheduleClear(p);
          final showGuide = p.isCameraReady && p.faceCount == 0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera
              if (p.isCameraReady)
                _CameraView(controller: p.camera.controller!)
              else
                const Center(child: CircularProgressIndicator(color: Colors.white)),

              // Guide frame
              if (showGuide) const FaceGuideOverlay(),

              // Subtle name labels (no boxes)
              if (p.isCameraReady && p.faceCount > 0)
                FaceOverlay(
                  faces: p.faces,
                  previewSize: Size(p.camera.controller!.value.previewSize!.height, p.camera.controller!.value.previewSize!.width),
                  matches: p.mode == AppMode.recognize ? p.faceMatches : null,
                ),

              // Center confidence % during recognize mode
              if (p.mode == AppMode.recognize && p.faceCount > 0 && p.highestConfidence != null)
                _CenterConfidence(confidence: p.highestConfidence!, matchedName: p.recognizedName),

              // >80% recognition banner
              if (p.recognizedName != null) _FoundBanner(name: p.recognizedName!),

              // 5s not-found banner
              if (p.notFound) const _NotFoundBanner(),

              // Top status pill
              Positioned(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, child: _TopPill(p: p)),

              // Bottom controls
              Positioned(bottom: MediaQuery.of(context).padding.bottom + 16, left: 20, right: 20, child: _BottomBar(p: p)),
            ],
          );
        },
      ),
    );
  }
}

// ── Top status pill ──
class _TopPill extends StatelessWidget {
  final FaceDetectionProvider p;
  const _TopPill({required this.p});
  @override
  Widget build(BuildContext context) {
    final isRecog = p.mode == AppMode.recognize;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: p.isDetecting ? Colors.green : Colors.red),
            ),
            const SizedBox(width: 10),
            Text(isRecog ? 'RECOGNIZE' : 'DETECT',
              style: TextStyle(color: isRecog ? Colors.greenAccent : Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
            const SizedBox(width: 12),
            Text(p.statusMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom control bar ──
class _BottomBar extends StatelessWidget {
  final FaceDetectionProvider p;
  const _BottomBar({required this.p});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PillBtn(icon: p.mode == AppMode.recognize ? Icons.fingerprint : Icons.search_off, label: p.mode == AppMode.recognize ? 'Recognize' : 'Detect', active: p.mode == AppMode.recognize, onTap: () => p.toggleMode()),
        const SizedBox(width: 10),
        _PillBtn(icon: Icons.person_add_alt, label: 'Register', active: false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: p, child: const RegisterFaceScreen())))),
        const SizedBox(width: 10),
        _PillBtn(icon: Icons.people_outline, label: '${p.registeredCount}', active: false, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: p, child: const RegisteredFacesScreen())))),
      ],
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _PillBtn({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: active ? Colors.teal.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: active ? Colors.tealAccent : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ── CameraView ──
class _CameraView extends StatelessWidget {
  final CameraController controller;
  const _CameraView({required this.controller});
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

// ── Found banner (>80%) ──
class _FoundBanner extends StatefulWidget {
  final String name;
  const _FoundBanner({required this.name});
  @override
  State<_FoundBanner> createState() => _FoundBannerState();
}

class _FoundBannerState extends State<_FoundBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600)); _a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack); _c.forward(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60, left: 24, right: 24,
      child: AnimatedBuilder(
        animation: _a,
        builder: (ctx, ch) => Transform.translate(offset: Offset(0, -30 * (1 - _a.value)), child: Opacity(opacity: _a.value, child: ch)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF009688)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFF00C853).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text('DIKENALI', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Not-found banner (5s timeout) ──
class _NotFoundBanner extends StatefulWidget {
  const _NotFoundBanner();
  @override
  State<_NotFoundBanner> createState() => _NotFoundBannerState();
}

class _NotFoundBannerState extends State<_NotFoundBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500)); _a = CurvedAnimation(parent: _c, curve: Curves.easeOutBack); _c.forward(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60, left: 24, right: 24,
      child: AnimatedBuilder(
        animation: _a,
        builder: (ctx, ch) => Transform.translate(offset: Offset(0, -30 * (1 - _a.value)), child: Opacity(opacity: _a.value, child: ch)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFF3D00)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6D00).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
              child: const Icon(Icons.person_off, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('TIDAK DIKENALI', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('Wajah tidak ditemukan dalam database', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Center confidence display ──
class _CenterConfidence extends StatelessWidget {
  final double confidence;
  final String? matchedName;
  const _CenterConfidence({required this.confidence, this.matchedName});

  Color get _color {
    if (confidence >= 80) return Colors.greenAccent;
    if (confidence >= 50) return Colors.orangeAccent;
    return Colors.white38;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress ring
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: confidence / 100,
                    strokeWidth: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(_color),
                  ),
                ),
                Text(
                  '${confidence.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: _color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (matchedName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Kemiripan',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Mencocokkan...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
