
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../controllers/workspace_controller.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import '../utils/wall_angle_detector.dart';
import '../widgets/premium_frame.dart';
import '../widgets/guest_save_modal.dart';
import '../main.dart'; // for globalCameras
import 'select_artwork_screen.dart';

// ---------------------------------------------------------------------------
// WorkspaceScreen — ArtSpace Interactive Canvas Editor
// Full-screen preview editor with:
//  • Pinch-to-scale and two-finger rotate gestures
//  • Drag to reposition artwork on wall background
//  • Collapsible glassmorphic sidebar with all editing tools
//  • Undo / Redo step-by-step history
//  • Compare toggle (hide/show artwork overlay)
//  • Delete / Add artwork toggle
//  • Done → locks editing, shows prominent Save button
//  • Firebase Auth-gated save with premium guest modal
// ---------------------------------------------------------------------------

class WorkspaceScreen extends StatefulWidget {
  final Uint8List? wallImageBytes;    // Camera/gallery wall photo (local bytes)
  final Uint8List? artworkImageBytes; // Local artwork file from device gallery
  final String? artworkNetworkUrl;    // Network URL from curated/collection gallery
  final String? artworkAssetPath;     // Local asset path (e.g. assets/images/...)
  final String? artworkId;            // Marketplace artwork ID
  final WallAngle? wallAngle;         // 3-D wall tilt captured at photo time

  const WorkspaceScreen({
    super.key,
    this.wallImageBytes,
    this.artworkImageBytes,
    this.artworkNetworkUrl,
    this.artworkAssetPath,
    this.artworkId,
    this.wallAngle,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

// ---------------------------------------------------------------------------
// Immutable snapshot of artwork transform for Undo / Redo
// ---------------------------------------------------------------------------
class TransformState {
  final double scale;
  final double rotation;
  final double left;
  final double top;

  const TransformState({
    required this.scale,
    required this.rotation,
    required this.left,
    required this.top,
  });
}

// ---------------------------------------------------------------------------
// _WorkspaceScreenState
// ---------------------------------------------------------------------------
class _WorkspaceScreenState extends State<WorkspaceScreen>
    with SingleTickerProviderStateMixin {

  // ── Artwork transform ──────────────────────────────────────────────────────
  double _artworkLeft = 0.0;
  double _artworkTop = 0.0;
  double _artworkScale = 1.0;
  double _artworkRotation = 0.0; // radians
  // Opacity is always 1.0 per spec (no opacity slider required)
  static const double _artworkOpacity = 1.0;

  late double _artworkWidth;
  late double _artworkHeight;
  bool _isArtworkSelected = true;

  // ── Editor mode ────────────────────────────────────────────────────────────
  final List<TransformState> _undoStack = [];
  final List<TransformState> _redoStack = [];
  final bool _isComparing = false;
  bool _hasChangedThisGesture = false;
  bool _isPanelCollapsed = false;

  // ── Active tool mode: 'move' | 'resize' | 'rotate' ────────────────────────
  String _activeMode = 'move';
  // Step-rotate accumulated counter (degrees)
  double _rotateStepDeg = 0;

  // ── 3-D Perspective angles (degrees) ──────────────────────────────────────
  double _perspectivePitch = 0.0; // vertical tilt in degrees
  double _perspectiveYaw = 0.0;   // horizontal tilt in degrees

  // ── Gesture tracking ───────────────────────────────────────────────────────
  double _gestureStartScale = 1.0;
  double _gestureStartRotation = 0.0;
  Offset _gestureStartFocalPoint = Offset.zero;
  double _gestureStartLeft = 0.0;
  double _gestureStartTop = 0.0;

  // ── Camera / rendering ─────────────────────────────────────────────────────
  CameraController? _cameraController;
  final GlobalKey _previewKey = GlobalKey();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Init live camera if requested
    final workspaceCtrl = context.read<WorkspaceController>();
    if (workspaceCtrl.isLiveCamera && globalCameras.isNotEmpty) {
      _cameraController = CameraController(
        globalCameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      }).catchError((Object e) { debugPrint('Camera error: $e'); return null; });
    }

    // Seed 3-D perspective from captured wall angle (if provided)
    if (widget.wallAngle != null) {
      _perspectivePitch = widget.wallAngle!.pitchDeg.clamp(-45.0, 45.0);
      _perspectiveYaw   = widget.wallAngle!.yawDeg.clamp(-45.0, 45.0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = MediaQuery.of(context).size;
    if (_artworkLeft == 0.0 && _artworkTop == 0.0) {
      _artworkWidth = screenSize.width * 0.52;
      _artworkHeight = _artworkWidth * 1.25;
      _artworkLeft = (screenSize.width - _artworkWidth) / 2;
      _artworkTop = (screenSize.height - _artworkHeight) / 2 - 60;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Undo / Redo helpers ────────────────────────────────────────────────────

  void _saveTransformState() {
    _undoStack.add(TransformState(
      scale: _artworkScale,
      rotation: _artworkRotation,
      left: _artworkLeft,
      top: _artworkTop,
    ));
    _redoStack.clear();
  }

  void _applyState(TransformState state) {
    _artworkScale = state.scale;
    _artworkRotation = state.rotation;
    _artworkLeft = state.left;
    _artworkTop = state.top;
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _redoStack.add(TransformState(
        scale: _artworkScale,
        rotation: _artworkRotation,
        left: _artworkLeft,
        top: _artworkTop,
      ));
      _applyState(_undoStack.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _undoStack.add(TransformState(
        scale: _artworkScale,
        rotation: _artworkRotation,
        left: _artworkLeft,
        top: _artworkTop,
      ));
      _applyState(_redoStack.removeLast());
    });
  }

  // ── Gesture handlers ───────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails details) {
    _hasChangedThisGesture = false;
    _gestureStartScale = _artworkScale;
    _gestureStartRotation = _artworkRotation;
    _gestureStartFocalPoint = details.focalPoint;
    _gestureStartLeft = _artworkLeft;
    _gestureStartTop = _artworkTop;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_isComparing) return; // gestures disabled in compare mode

    final screenSize = MediaQuery.of(context).size;
    final Offset delta = details.focalPoint - _gestureStartFocalPoint;

    final double newScale =
        (_gestureStartScale * details.scale).clamp(0.15, 5.0);
    final double newRotation = _gestureStartRotation + details.rotation;

    // Allow partial off-screen but never fully invisible
    final scaledW = _artworkWidth * newScale;
    final scaledH = _artworkHeight * newScale;
    final double maxLeft = screenSize.width - scaledW * 0.25;
    final double maxTop  = screenSize.height - scaledH * 0.25;
    final double minLeft = -scaledW * 0.75;
    final double minTop  = -scaledH * 0.75;

    final double newLeft = (_gestureStartLeft + delta.dx).clamp(minLeft, maxLeft);
    final double newTop  = (_gestureStartTop  + delta.dy).clamp(minTop, maxTop);

    // Save to undo stack only once per gesture sequence
    if (!_hasChangedThisGesture) {
      final moved = (newScale - _gestureStartScale).abs() > 0.01 ||
          (newRotation - _gestureStartRotation).abs() > 0.005 ||
          delta.distance > 2.0;
      if (moved) {
        _saveTransformState();
        _hasChangedThisGesture = true;
      }
    }

    setState(() {
      _artworkLeft = newLeft;
      _artworkTop = newTop;
      _artworkScale = newScale;
      _artworkRotation = newRotation;
    });
  }

  // ── Toolbar actions ────────────────────────────────────────────────────────


  void _removeArtwork() {
    HapticFeedback.lightImpact();
    context.read<WorkspaceController>().clearArtworkSelection();
    setState(() {});
  }

  void _resetTransforms() {
    HapticFeedback.mediumImpact();
    _saveTransformState();
    final screenSize = MediaQuery.of(context).size;
    setState(() {
      _artworkScale = 1.0;
      _artworkRotation = 0.0;
      _rotateStepDeg = 0;
      _artworkLeft = (screenSize.width - _artworkWidth) / 2;
      _artworkTop = (screenSize.height - _artworkHeight) / 2 - 60;
      _activeMode = 'move';
      // Also reset 3-D perspective
      _perspectivePitch = widget.wallAngle?.pitchDeg.clamp(-45.0, 45.0) ?? 0.0;
      _perspectiveYaw   = widget.wallAngle?.yawDeg.clamp(-45.0, 45.0) ?? 0.0;
    });
  }

  void _stepRotate(double degrees) {
    HapticFeedback.selectionClick();
    _saveTransformState();
    setState(() {
      _rotateStepDeg += degrees;
      _artworkRotation = _rotateStepDeg * (math.pi / 180);
    });
  }

  // ── Save Preview ───────────────────────────────────────────────────────────

  Future<void> _savePreview() async {
    HapticFeedback.mediumImpact();
    final authCtrl = context.read<AuthController>();

    // Guest user → show premium modal encouraging sign-up
    if (!authCtrl.isAuthenticated) {
      showGuestSaveModal(context);
      return;
    }

    final workspaceCtrl = context.read<WorkspaceController>();

    // Hide selection handles before capture
    setState(() => _isArtworkSelected = false);
    await Future.delayed(const Duration(milliseconds: 120));

    // Capture composite image
    Uint8List? compositeBytes;
    try {
      final boundary =
          _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image img = await boundary.toImage(pixelRatio: 1.5);
        final ByteData? byteData =
            await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) compositeBytes = byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }

    if (!mounted) return;

    // Loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
      ),
    );

    final success = await workspaceCtrl.savePreview(
      positionLeft: _artworkLeft,
      positionTop: _artworkTop,
      scale: _artworkScale,
      rotation: _artworkRotation,
      compositeBytes: compositeBytes,
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading dialog

    if (success) {
      _showSuccessSnackBar('Preview saved to My Collection → Saved Previews!');
    } else {
      _showErrorSnackBar('Failed to save: ${workspaceCtrl.saveError}');
    }
  }



  // ── Snackbar helpers ───────────────────────────────────────────────────────

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: const Color(0xFF38322B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent.shade700,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
    ));
  }

  // ── Top Header Actions ─────────────────────────────────────────────────────

  Widget _buildTopActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.maybePop(context),
            ),
            Row(
              children: [
                _NavButton(
                  icon: Icons.undo_rounded,
                  onTap: _undoStack.isNotEmpty ? _undo : null,
                  isActive: _undoStack.isNotEmpty,
                ),
                const SizedBox(width: 12),
                _NavButton(
                  icon: Icons.redo_rounded,
                  onTap: _redoStack.isNotEmpty ? _redo : null,
                  isActive: _redoStack.isNotEmpty,
                ),
                const SizedBox(width: 12),
                _NavButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () {}, // TODO: Implement share
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Panel (draggable/collapsible) ───────────────────────────────────

  Widget _buildBottomPanel() {
    final workspaceCtrl = context.watch<WorkspaceController>();
    final hasArtwork = workspaceCtrl.selectedArtworkId != null ||
        workspaceCtrl.selectedArtworkNetworkUrl != null ||
        workspaceCtrl.selectedArtworkAssetPath != null ||
        workspaceCtrl.artworkImageBytes != null;

    return GestureDetector(
      // Drag down to collapse, drag up to expand
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy > 200) {
          setState(() => _isPanelCollapsed = true);
        } else if (details.velocity.pixelsPerSecond.dy < -200) {
          setState(() => _isPanelCollapsed = false);
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ─────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _isPanelCollapsed = !_isPanelCollapsed),
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1A16).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // ── Expanded content (hidden when collapsed) ─────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              crossFadeState: _isPanelCollapsed
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Tool Row (Move, Rotate, Reset, Delete)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionIconButton(
                          icon: Icons.open_with_rounded,
                          label: 'Move',
                          onTap: () => setState(() => _activeMode = 'move'),
                          isActive: _activeMode == 'move',
                          activeColor: const Color(0xFF4A3424),
                        ),
                        _ActionIconButton(
                          icon: Icons.rotate_right_rounded,
                          label: 'Rotate',
                          onTap: () => setState(() => _activeMode = 'rotate'),
                          isActive: _activeMode == 'rotate',
                          activeColor: const Color(0xFF4A3424),
                        ),
                        _ActionIconButton(
                          icon: Icons.view_in_ar_rounded,
                          label: '3D',
                          onTap: () => setState(() => _activeMode = '3d'),
                          isActive: _activeMode == '3d',
                          activeColor: const Color(0xFF1A6B8A),
                        ),
                        _ActionIconButton(
                          icon: Icons.restart_alt_rounded,
                          label: 'Reset',
                          onTap: _resetTransforms,
                        ),
                        if (hasArtwork)
                          _ActionIconButton(
                            icon: Icons.delete_outline_rounded,
                            label: 'Delete',
                            onTap: _removeArtwork,
                          )
                        else
                          _ActionIconButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Add',
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SelectArtworkScreen(isFromCamera: true),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Contextual controls based on active mode
                    if (!_isComparing) ..._buildModeControls(),

                    const SizedBox(height: 24),

                    // 3. Save Button
                    _AnimatedSaveButton(onTap: _savePreview),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Contextual controls for the selected tool mode
  List<Widget> _buildModeControls() {
    switch (_activeMode) {
      case 'rotate':
        return [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Rotate',
                style: TextStyle(
                  color: Color(0xFF1E1A16),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => _stepRotate(-15),
                child: _CircleBtn(icon: Icons.rotate_left_rounded),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFECE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_rotateStepDeg % 360).toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Color(0xFF4A3424),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _stepRotate(15),
                child: _CircleBtn(icon: Icons.rotate_right_rounded),
              ),
            ],
          ),
        ];

      case '3d':
        return _build3DControls();

      default: // 'move'
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text(
                  'Size',
                  style: TextStyle(
                    color: Color(0xFF1E1A16),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _stepScale(-0.05),
                  child: _CircleBtn(icon: Icons.remove_rounded),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      activeTrackColor: const Color(0xFF4A3424),
                      inactiveTrackColor: const Color(0xFFEFECE8),
                      thumbColor: const Color(0xFF4A3424),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayColor: const Color(0xFF4A3424).withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: _artworkScale,
                      min: 0.15,
                      max: 5.0,
                      onChangeStart: (_) {
                        _gestureStartScale = _artworkScale;
                        _gestureStartRotation = _artworkRotation;
                        _gestureStartLeft = _artworkLeft;
                        _gestureStartTop = _artworkTop;
                      },
                      onChanged: (val) => setState(() => _artworkScale = val),
                      onChangeEnd: (val) {
                        if ((val - _gestureStartScale).abs() > 0.01) {
                          _saveTransformState();
                        }
                      },
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _stepScale(0.05),
                  child: _CircleBtn(icon: Icons.add_rounded),
                ),
              ],
            ),
          ),
        ];
    }
  }

  // ── 3-D Perspective controls ───────────────────────────────────────────────

  List<Widget> _build3DControls() {
    const teal = Color(0xFF1A6B8A);
    final sliderTheme = SliderThemeData(
      trackHeight: 4,
      activeTrackColor: teal,
      inactiveTrackColor: const Color(0xFFEFECE8),
      thumbColor: teal,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayColor: teal.withValues(alpha: 0.12),
    );
    return [
      // Title row with badge
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.view_in_ar_rounded, size: 16, color: teal),
          const SizedBox(width: 6),
          const Text(
            '3D Wall Perspective',
            style: TextStyle(
              color: teal,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() {
              _perspectivePitch = 0;
              _perspectiveYaw   = 0;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: teal.withValues(alpha: 0.30)),
              ),
              child: const Text(
                'Flat',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: teal),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      // Vertical tilt slider (pitch)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const SizedBox(width: 4),
            const Icon(Icons.height_rounded, size: 16, color: teal),
            const SizedBox(width: 6),
            const Text(
              'Up/Down',
              style: TextStyle(
                color: Color(0xFF1E1A16),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: _perspectivePitch,
                  min: -45,
                  max: 45,
                  onChanged: (v) => setState(() => _perspectivePitch = v),
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${_perspectivePitch.toStringAsFixed(0)}°',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: teal,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      // Horizontal tilt slider (yaw)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz_rounded, size: 16, color: teal),
            const SizedBox(width: 6),
            const Text(
              'Left/Right',
              style: TextStyle(
                color: Color(0xFF1E1A16),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: _perspectiveYaw,
                  min: -45,
                  max: 45,
                  onChanged: (v) => setState(() => _perspectiveYaw = v),
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                '${_perspectiveYaw.toStringAsFixed(0)}°',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: teal,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _stepScale(double delta) {
    HapticFeedback.selectionClick();
    _saveTransformState();
    setState(() {
      _artworkScale = (_artworkScale + delta).clamp(0.15, 5.0);
    });
  }

  // ── Compare mode label overlay ─────────────────────────────────────────────

  Widget _buildCompareLabel() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _isComparing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.visibility_off_rounded,
                    color: Color(0xFF7DBCFF), size: 14),
                SizedBox(width: 6),
                Text(
                  'COMPARE MODE — Artwork hidden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Artwork canvas ─────────────────────────────────────────────────────────

  Widget _buildArtworkCanvas() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onTap: () => setState(() => _isArtworkSelected = !_isArtworkSelected),
      child: Stack(
        children: [
          Positioned(
            left: _artworkLeft,
            top: _artworkTop,
            child: GestureDetector(
              onTap: () => setState(() => _isArtworkSelected = true),
              child: Transform(
                alignment: Alignment.center,
                // ── Outer: 3-D wall perspective (pitch + yaw) ──────────────
                transform: _buildPerspectiveMatrix(),
                child: Transform(
                  alignment: Alignment.center,
                  // ── Inner: 2-D scale + flat rotation ───────────────────────
                  transform: Matrix4.diagonal3Values(
                          _artworkScale, _artworkScale, 1.0)
                    ..rotateZ(_artworkRotation),
                  child: Opacity(
                    opacity: _artworkOpacity,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ── Framed artwork image ─────────────────────────
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.80,
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.70,
                          ),
                          child: _isComparing
                              ? const SizedBox.shrink()
                              : PremiumFrame(child: _buildArtworkImage()),
                        ),

                        // ── Selection handles (dashed border + dots) ──────
                        if (_isArtworkSelected && !_isComparing)
                          Positioned.fill(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                      painter: _DashedBorderPainter()),
                                ),
                                for (final align in _handleAlignments)
                                  _Handle(alignment: align),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the outer 3-D perspective Matrix4 from pitch/yaw sliders.
  /// setEntry(3,2) adds perspective depth so far edges appear smaller.
  Matrix4 _buildPerspectiveMatrix() {
    final pitchRad = _perspectivePitch * math.pi / 180.0;
    final yawRad = _perspectiveYaw * math.pi / 180.0;
    return Matrix4.identity()
      ..setEntry(3, 2, 0.0015) // perspective depth
      ..rotateX(-pitchRad) // vertical tilt
      ..rotateY(yawRad); // horizontal tilt
  }

  Widget _buildArtworkImage() {
    if (widget.artworkImageBytes != null) {
      return Image.memory(
        widget.artworkImageBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }
    if (widget.artworkNetworkUrl != null) {
      return Image.network(
        widget.artworkNetworkUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stack) => _PlaceholderArtwork(
          width: _artworkWidth,
          height: _artworkHeight,
        ),
      );
    }
    if (widget.artworkAssetPath != null) {
      return Image.asset(
        widget.artworkAssetPath!,
        fit: BoxFit.contain,
      );
    }
    return _PlaceholderArtwork(width: _artworkWidth, height: _artworkHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Capture boundary (wall + artwork composite) ───────────────────
          RepaintBoundary(
            key: _previewKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _WallBackground(
                  imageBytes: widget.wallImageBytes,
                  cameraController: _cameraController,
                ),
                _buildArtworkCanvas(),
              ],
            ),
          ),

          // ── Compare label ─────────────────────────────────────────────────
          _buildCompareLabel(),

          // ── Top actions (Back, Undo, Redo) ────────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: _buildTopActions(),
          ),

          // ── Bottom Panel ──────────────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Handle alignment list
// ============================================================================
const List<AlignmentGeometry> _handleAlignments = [
  Alignment.topLeft,
  Alignment.topCenter,
  Alignment.topRight,
  Alignment.centerLeft,
  Alignment.centerRight,
  Alignment.bottomLeft,
  Alignment.bottomCenter,
  Alignment.bottomRight,
];



// ============================================================================
// _CircleBtn — small circular icon button used inside control panels
// ============================================================================
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  const _CircleBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFEFECE8),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF1E1A16), size: 20),
    );
  }
}

// ============================================================================
// _AnimatedSaveButton — glowing CTA after Done is pressed
// ============================================================================
class _AnimatedSaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedSaveButton({required this.onTap});

  @override
  State<_AnimatedSaveButton> createState() => _AnimatedSaveButtonState();
}

class _AnimatedSaveButtonState extends State<_AnimatedSaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5D4037), Color(0xFF38322B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5D4037).withValues(alpha: _glowAnim.value),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.save_alt_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Save to My Collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _WallBackground
// ============================================================================
class _WallBackground extends StatelessWidget {
  final Uint8List? imageBytes;
  final CameraController? cameraController;
  const _WallBackground({this.imageBytes, this.cameraController});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (cameraController != null && cameraController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: cameraController!.value.previewSize?.height ?? size.width,
            height: cameraController!.value.previewSize?.width ?? size.height,
            child: CameraPreview(cameraController!),
          ),
        ),
      );
    }

    if (imageBytes != null) {
      return SizedBox.expand(
        child: Image.memory(
          imageBytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    }

    // Fallback decorative wall gradient
    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD4C4B0), Color(0xFFC8B49A), Color(0xFF8B7355)],
          stops: [0.0, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.28,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x556B5140)],
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.08,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Wall Placeholder',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _PlaceholderArtwork — shown when no artwork image is loaded
// ============================================================================
class _PlaceholderArtwork extends StatelessWidget {
  final double width;
  final double height;
  const _PlaceholderArtwork({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(8, 16),
          ),
        ],
      ),
      child: CustomPaint(painter: _AbstractArtPainter()),
    );
  }
}

class _AbstractArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFE8D5BC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final wavePath = Path()
      ..moveTo(0, size.height * 0.3)
      ..cubicTo(size.width * 0.3, size.height * 0.1, size.width * 0.4,
          size.height * 0.5, size.width * 0.5, size.height * 0.7)
      ..cubicTo(size.width * 0.6, size.height * 0.9, size.width * 0.2,
          size.height * 0.95, 0, size.height)
      ..close();
    paint.color = const Color(0xFF2C2218);
    canvas.drawPath(wavePath, paint);

    final arcPath = Path()
      ..moveTo(size.width * 0.55, 0)
      ..quadraticBezierTo(
          size.width * 1.1, size.height * 0.2, size.width, size.height * 0.55)
      ..lineTo(size.width, 0)
      ..close();
    paint.color = const Color(0xFFA0714F);
    canvas.drawPath(arcPath, paint);

    paint.color = const Color(0xFFBFA07A);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.38, size.width * 0.5,
          size.height * 0.18),
      paint,
    );

    paint.color = const Color(0xFF1E1A16);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.28),
      size.width * 0.08,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// _Handle — corner/edge drag handle dots on the bounding box
// ============================================================================
class _Handle extends StatelessWidget {
  final AlignmentGeometry alignment;
  const _Handle({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF38322B), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _DashedBorderPainter — animated selection border
// ============================================================================
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashWidth = 6.0;
    const double dashGap = 4.5;
    const double strokeWidth = 1.8;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    void drawDashedLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final length = math.sqrt(dx * dx + dy * dy);
      final nx = dx / length;
      final ny = dy / length;
      double drawn = 0;
      while (drawn < length) {
        final segEnd = (drawn + dashWidth).clamp(0.0, length);
        canvas.drawLine(
          Offset(start.dx + nx * drawn, start.dy + ny * drawn),
          Offset(start.dx + nx * segEnd, start.dy + ny * segEnd),
          paint,
        );
        drawn += dashWidth + dashGap;
      }
    }

    drawDashedLine(Offset.zero, Offset(size.width, 0));
    drawDashedLine(Offset(size.width, 0), Offset(size.width, size.height));
    drawDashedLine(Offset(size.width, size.height), Offset(0, size.height));
    drawDashedLine(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// _NavButton — glassmorphic back button
// ============================================================================
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  const _NavButton({
    required this.icon,
    this.onTap,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: isActive ? 0.18 : 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: isActive ? 0.28 : 0.05),
                  width: 1),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.3), size: 18),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _ActionIconButton — icon + label button used inside the action bar
// ============================================================================
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? activeColor;
  final bool destructive;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
    this.activeColor,
    // ignore: unused_element_parameter
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    if (onTap == null) {
      iconColor = const Color(0xFF1E1A16).withValues(alpha: 0.25);
    } else if (destructive) {
      iconColor = const Color(0xFFE57373);
    } else if (isActive) {
      iconColor = activeColor ?? const Color(0xFF4A3424);
    } else {
      iconColor = const Color(0xFF1E1A16).withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.35 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(

              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
