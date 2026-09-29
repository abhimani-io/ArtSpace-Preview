import 'package:flutter/material.dart';
import '../models/preview_model.dart';
import '../utils/app_theme.dart';

// ---------------------------------------------------------------------------
// CompareScreen — ArtSpace Preview (Screen #7)
// Shows a Before / After slider comparison of the same room:
//  • Left side: the plain wall photo (Before)
//  • Right side: the artwork overlaid on the wall (After)
// The user drags the central divider handle to reveal more of either side.
// ---------------------------------------------------------------------------

class CompareScreen extends StatefulWidget {
  final PreviewModel preview;

  const CompareScreen({super.key, required this.preview});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  // The divider position as a fraction of total width (0.0 = all Before, 1.0 = all After)
  double _dividerPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top bar ---
            _buildTopBar(context),

            const SizedBox(height: 12),

            // --- Compare Slider Area ---
            Expanded(
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dividerPosition = (_dividerPosition +
                            details.delta.dx / size.width)
                        .clamp(0.05, 0.95);
                  });
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // --- AFTER layer (full width, clipped on left) ---
                      Positioned.fill(
                        child: _buildAfterLayer(),
                      ),

                      // --- BEFORE layer (clipped on the right side of the divider) ---
                      Positioned.fill(
                        child: ClipRect(
                          clipper: _LeftClipper(_dividerPosition),
                          child: _buildBeforeLayer(),
                        ),
                      ),

                      // --- Before / After labels ---
                      Positioned(
                        top: 12,
                        left: 16,
                        child: _buildLabel('Before', isLeft: true),
                      ),
                      Positioned(
                        top: 12,
                        right: 16,
                        child: _buildLabel('After', isLeft: false),
                      ),

                      // --- Divider line and drag handle ---
                      Positioned(
                        left: _dividerPosition * size.width,
                        top: 0,
                        bottom: 0,
                        child: _buildDivider(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Navigation arrows at bottom ---
            _buildNavigationArrows(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
          ),
          const Spacer(),
          const Text(
            'Compare',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Placeholder right side (symmetric with back arrow)
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  // The "Before" half — just the plain wall photo
  Widget _buildBeforeLayer() {
    return widget.preview.wallImageUrl != null
        ? Image.network(
            widget.preview.wallImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, _, _) => _buildGradientPlaceholder(),
          )
        : _buildGradientPlaceholder();
  }

  // The "After" half — the wall with artwork overlaid (simplified: shows artwork image)
  Widget _buildAfterLayer() {
    return Stack(
      children: [
        // Background wall
        if (widget.preview.wallImageUrl != null)
          Positioned.fill(
            child: Image.network(
              widget.preview.wallImageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildGradientPlaceholder(),
            ),
          )
        else
          Positioned.fill(child: _buildGradientPlaceholder()),

        // Artwork overlay (centered, scaled per saved parameters)
        if (widget.preview.artworkImageUrl != null)
          Center(
            child: Transform.scale(
              scale: widget.preview.scale.clamp(0.5, 1.5),
              child: Transform.rotate(
                angle: widget.preview.rotation,
                child: Opacity(
                  opacity: widget.preview.opacity,
                  child: Container(
                    width: 180,
                    height: 220,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(6, 10),
                        ),
                      ],
                    ),
                    child: Image.network(
                      widget.preview.artworkImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD4C4B0), Color(0xFF8B7355)],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isLeft}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLeft ? Colors.white.withValues(alpha: 0.9) : AppTheme.primaryAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isLeft ? AppTheme.textDark : Colors.white,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return SizedBox(
      width: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Vertical line
          Positioned.fill(
            child: Container(
              width: 2,
              color: Colors.white,
            ),
          ),
          // Circular drag handle
          Positioned(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left,
                      size: 16, color: AppTheme.textDark),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppTheme.textDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArrows(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _LeftClipper — clips a widget to show only its left portion
// Used to reveal the "Before" photo up to the divider position
// ---------------------------------------------------------------------------
class _LeftClipper extends CustomClipper<Rect> {
  final double fraction; // 0.0 to 1.0

  const _LeftClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_LeftClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
