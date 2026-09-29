import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../controllers/workspace_controller.dart';
import '../main.dart'; // for globalCameras
import '../models/artwork_model.dart';
import '../utils/app_theme.dart';
import '../utils/wall_angle_detector.dart';
import 'select_artwork_screen.dart';
import 'workspace_screen.dart';

// ---------------------------------------------------------------------------
// CustomCameraScreen — ArtSpace Preview
// Custom camera interface for taking a picture of a wall. Shows a preview
// and allows navigating to Catalog or AR Workspace depending on context.
//
// New: accepts an optional [preselectedArtwork] parameter. When provided,
// the screen shows an artwork thumbnail strip and navigates directly to
// WorkspaceScreen after the wall photo is captured.
// ---------------------------------------------------------------------------

class CustomCameraScreen extends StatefulWidget {
  final String originSource; // 'wall_drop' or 'art_hunt'

  /// When set, the artwork grid flow passes the artwork directly here,
  /// bypassing ArtworkDetailsScreen entirely.
  final ArtworkModel? preselectedArtwork;

  const CustomCameraScreen({
    super.key,
    this.originSource = 'wall_drop',
    this.preselectedArtwork,
  });

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  XFile? _capturedImage;

  // ── 3-D wall-angle detector ────────────────────────────────────────────────
  final WallAngleDetector _angleDetector = WallAngleDetector();
  WallAngle? _capturedAngle; // frozen at shutter press

  // Animation for the artwork thumbnail strip
  late final AnimationController _stripCtrl;
  late final Animation<Offset> _stripSlide;
  late final Animation<double> _stripFade;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _angleDetector.start(); // begin reading accelerometer

    _stripCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stripSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _stripCtrl, curve: Curves.easeOutCubic));
    _stripFade = CurvedAnimation(parent: _stripCtrl, curve: Curves.easeOut);
    _stripCtrl.forward();
  }

  Future<void> _initCamera() async {
    if (globalCameras.isEmpty) return;

    // Pick the first back camera
    final camera = globalCameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => globalCameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _stripCtrl.dispose();
    _angleDetector.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Freeze the wall angle at the exact moment of capture
      _capturedAngle = _angleDetector.capture();
      final image = await _controller!.takePicture();
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  Future<void> _proceed() async {
    if (_capturedImage == null) return;

    final bytes = await _capturedImage!.readAsBytes();
    if (!mounted) return;

    final workspaceCtrl = context.read<WorkspaceController>();
    workspaceCtrl.wallImageBytes = bytes;
    workspaceCtrl.isLiveCamera = false;

    // ── Art Hunt Flow ────────────────────────────────────────────────────────
    if (widget.originSource == 'art_hunt' && widget.preselectedArtwork != null) {
      final art = widget.preselectedArtwork!;
      
      // Persist selection so WorkspaceController is aware for saving
      if (art.isLocalAsset) {
        workspaceCtrl.setSelectedLocalAsset(art.imageUrl);
      } else {
        workspaceCtrl.setSelectedMarketplaceArtwork(
          artworkId: art.id,
          networkUrl: art.imageUrl,
        );
      }

      Navigator.pushReplacement(
        context,
        _buildPreviewRoute(
          wallBytes: bytes,
          assetPath: art.isLocalAsset ? art.imageUrl : null,
          networkUrl: art.isLocalAsset ? null : art.imageUrl,
          artworkId: art.isLocalAsset ? null : art.id,
        ),
      );
      return;
    }

    // ── Wall Drop Flow ───────────────────────────────────────────────────────
    if (widget.originSource == 'wall_drop') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SelectArtworkScreen(isFromCamera: true),
        ),
      );
      return;
    }
  }

  MaterialPageRoute<void> _buildPreviewRoute({
    required Uint8List wallBytes,
    String? assetPath,
    String? networkUrl,
    String? artworkId,
  }) {
    return MaterialPageRoute(
      builder: (_) => WorkspaceScreen(
        wallImageBytes: wallBytes,
        artworkAssetPath: assetPath,
        artworkNetworkUrl: networkUrl,
        artworkId: artworkId,
        wallAngle: _capturedAngle, // ← pass captured 3-D angle
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedImage != null) {
      return _buildPreview();
    }
    return _buildCamera();
  }

  // ── Camera viewfinder ────────────────────────────────────────────────────

  Widget _buildCamera() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child:
                CircularProgressIndicator(color: AppTheme.primaryAccent)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen camera preview
          Positioned.fill(child: CameraPreview(_controller!)),

          // Corner guide lines overlay
          Positioned.fill(child: _buildGuideLines()),

          // ── Live 3-D tilt indicator ───────────────────────────────────
          Positioned.fill(
            child: ValueListenableBuilder<WallAngle>(
              valueListenable: _angleDetector.angle,
              builder: (_, angle, child) => _WallTiltOverlay(angle: angle),
            ),
          ),

          // ── Artwork thumbnail strip (new) ─────────────────────────────
          if (widget.preselectedArtwork != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _stripSlide,
                child: FadeTransition(
                  opacity: _stripFade,
                  child: _buildArtworkStrip(widget.preselectedArtwork!),
                ),
              ),
            ),

          // ── Close button ──────────────────────────────────────────────
          Positioned(
            top: widget.preselectedArtwork != null ? 110 : 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),

          // ── Instruction label ─────────────────────────────────────────
          Positioned(
            top: widget.preselectedArtwork != null ? 118 : 58,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  widget.preselectedArtwork != null
                      ? 'Point at your wall to place the artwork'
                      : 'Point at your wall',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom capture button ─────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Capture button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(colors: [
                            Colors.white,
                            Color(0xFFE0D4C8),
                          ]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to capture',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Artwork thumbnail strip shown at the top of the camera ────────────────

  Widget _buildArtworkStrip(ArtworkModel art) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Artwork thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.7),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: art.isLocalAsset
                      ? Image.asset(art.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Container(
                              color: const Color(0xFF3E2723)))
                      : Image.network(art.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Container(
                              color: const Color(0xFF3E2723))),
                ),
              ),
              const SizedBox(width: 14),
              // Artwork info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.primaryAccent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryAccent
                                  .withValues(alpha: 0.6),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 10, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Selected',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      art.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${art.environmentCategory} · ${art.environmentSubcategory}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Pulse AR icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.view_in_ar_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Corner guide lines for the viewfinder ─────────────────────────────────

  Widget _buildGuideLines() {
    return CustomPaint(painter: _GuideLinePainter());
  }

  // ── Photo preview screen ──────────────────────────────────────────────────

  Widget _buildPreview() {
    final ArtworkModel? art = widget.preselectedArtwork;
    final bool hasArt = widget.originSource == 'art_hunt' && art != null;
    final String btnText =
        hasArt ? 'Preview on Wall' : 'Add Artwork';
    final IconData btnIcon =
        hasArt ? Icons.view_in_ar_rounded : Icons.add_photo_alternate_rounded;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.cover,
            ),
          ),

          // ── Artwork overlay ghost (shows selected art as semi-transparent) ─
          if (art != null)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 60),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: art.isLocalAsset
                          ? Image.asset(art.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, e, s) =>
                                  const SizedBox.shrink())
                          : Image.network(art.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, e, s) =>
                                  const SizedBox.shrink()),
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom action bar ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 44),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.92),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status label
                  if (art != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Wall captured',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    art != null
                        ? 'Ready to preview "${art.name}" on your wall!'
                        : 'Wall captured! Now pick your artwork.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    art != null
                        ? 'Tap below to launch the interactive preview.'
                        : 'Tap \'Add Artwork\' to choose wall art for this wall.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Retake
                      GestureDetector(
                        onTap: _retakePicture,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Retake',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Proceed
                      Expanded(
                        child: GestureDetector(
                          onTap: _proceed,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF8D6E63),
                                  AppTheme.primaryAccent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryAccent
                                      .withValues(alpha: 0.5),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(btnIcon,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  btnText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Corner guide-line painter — draws subtle L-shaped brackets on the viewfinder
// ---------------------------------------------------------------------------
class _GuideLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const margin = 24.0;

    final corners = [
      // Top-left
      [Offset(margin, margin + len), Offset(margin, margin),
          Offset(margin + len, margin)],
      // Top-right
      [
        Offset(size.width - margin - len, margin),
        Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + len)
      ],
      // Bottom-left
      [
        Offset(margin, size.height - margin - len),
        Offset(margin, size.height - margin),
        Offset(margin + len, size.height - margin)
      ],
      // Bottom-right
      [
        Offset(size.width - margin - len, size.height - margin),
        Offset(size.width - margin, size.height - margin),
        Offset(size.width - margin, size.height - margin - len)
      ],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// _WallTiltOverlay — live 3-D angle indicator drawn on the camera viewfinder.
// Shows a central crosshair that shifts with pitch/yaw and a status badge.
// ---------------------------------------------------------------------------
class _WallTiltOverlay extends StatelessWidget {
  final WallAngle angle;
  const _WallTiltOverlay({required this.angle});

  // Colour ramp: green (straight) → amber (slight) → red (steep)
  Color get _indicatorColor {
    final i = angle.intensity;
    if (i < 0.25) return const Color(0xFF69F0AE); // green
    if (i < 0.55) return const Color(0xFFFFD740); // amber
    return const Color(0xFFFF5252);                // red
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Crosshair offset — max 60 px displacement
    final dx = (angle.yawDeg / 45.0).clamp(-1.0, 1.0) * 60.0;
    final dy = (angle.pitchDeg / 45.0).clamp(-1.0, 1.0) * -60.0;

    return Stack(
      children: [
        // ── Angle indicator crosshair ──────────────────────────────────────
        Positioned(
          left: size.width / 2 - 28 + dx,
          top: size.height / 2 - 28 + dy,
          child: CustomPaint(
            size: const Size(56, 56),
            painter: _TiltCrosshairPainter(color: _indicatorColor),
          ),
        ),

        // ── Horizontal level bar ───────────────────────────────────────────
        Positioned(
          left: size.width * 0.15,
          right: size.width * 0.15,
          top: size.height / 2 - 1,
          child: CustomPaint(
            size: Size(size.width * 0.70, 2),
            painter: _LevelBarPainter(
              yawFraction: (angle.yawDeg / 45.0).clamp(-1.0, 1.0),
              color: _indicatorColor,
            ),
          ),
        ),

        // ── Status badge (bottom-right of screen) ─────────────────────────
        Positioned(
          right: 20,
          bottom: 160,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _indicatorColor.withValues(alpha: 0.7), width: 1.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.view_in_ar_rounded,
                        size: 12, color: _indicatorColor),
                    const SizedBox(width: 5),
                    Text(
                      angle.label,
                      style: TextStyle(
                        color: _indicatorColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'P: ${angle.pitchDeg.toStringAsFixed(1)}°  '
                  'Y: ${angle.yawDeg.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Crosshair painter: two perpendicular lines + a filled centre circle
class _TiltCrosshairPainter extends CustomPainter {
  final Color color;
  const _TiltCrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), linePaint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), linePaint);
    canvas.drawCircle(Offset(cx, cy), 5, dotPaint);
  }

  @override
  bool shouldRepaint(_TiltCrosshairPainter o) => o.color != color;
}

// Horizontal level bar — shifts position proportionally to yaw
class _LevelBarPainter extends CustomPainter {
  final double yawFraction; // -1 to 1
  final Color color;
  const _LevelBarPainter({required this.yawFraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final indicatorPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // Full track
    canvas.drawLine(Offset.zero, Offset(size.width, 0), trackPaint);
    // Moving indicator (20 % of bar width)
    final span = size.width * 0.20;
    final centre = size.width / 2 + yawFraction * (size.width / 2 - span / 2);
    canvas.drawLine(
      Offset(centre - span / 2, 0),
      Offset(centre + span / 2, 0),
      indicatorPaint,
    );
    // Centre tick
    canvas.drawLine(
      Offset(size.width / 2, -6),
      Offset(size.width / 2, 6),
      trackPaint,
    );
  }

  @override
  bool shouldRepaint(_LevelBarPainter o) =>
      o.yawFraction != yawFraction || o.color != color;
}

// Helper — interpolate double (used in _LevelBarPainter)
double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

