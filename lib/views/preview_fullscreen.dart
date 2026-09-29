import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../models/preview_model.dart';
import '../utils/app_theme.dart';
import 'compare_screen.dart';
import 'login_screen.dart';
import 'cart_screen.dart';
import '../controllers/shop_controller.dart';

// ---------------------------------------------------------------------------
// PreviewFullScreen — ArtSpace Preview (Screen #6)
// Shows a single saved preview in a full-screen immersive viewer.
// The user can share, open the 3-dot options menu, or jump to the
// Before/After compare view. The preview name and date float over the
// image at the bottom.
// ---------------------------------------------------------------------------

class PreviewFullScreen extends StatelessWidget {
  final PreviewModel preview;
  final String imageUrl;

  const PreviewFullScreen({
    super.key,
    required this.preview,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Make the status bar fully transparent for full-screen immersion
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // --- Full-screen composite image ---
            Positioned.fill(
              child: imageUrl.isNotEmpty
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: SizedBox.expand(
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const _PlaceholderWall(),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const _PlaceholderWall(),
                              ),
                      ),
                    )
                  : const _PlaceholderWall(),
            ),

            // --- Gradient overlay at top and bottom ---
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.25, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            // --- Top Action Bar (Back, Share, More) ---
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _GlassButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    _GlassButton(
                      icon: Icons.share_outlined,
                      onTap: () {
                        // TODO: Integrate share_plus package for native share sheet
                        HapticFeedback.selectionClick();
                      },
                    ),
                    const SizedBox(width: 10),
                    _GlassButton(
                      icon: Icons.more_vert_rounded,
                      onTap: () => _showOptionsMenu(context),
                    ),
                  ],
                ),
              ),
            ),

            // --- Bottom overlay: preview name, date, and Edit button ---
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Preview metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              preview.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${preview.formattedDate} • ${TimeOfDay.now().format(context)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (preview.hasPurchasableArtwork) ...[
                        GestureDetector(
                          onTap: () async {
                            final auth = context.read<AuthController>();
                            if (!auth.isAuthenticated) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                              return;
                            }
                            final artwork = await context.read<FirestoreService>().getPublicArtwork(preview.artworkId!);
                            if (!context.mounted || artwork == null) return;
                            context.read<ShopController>().addToCart(artwork);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Buy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Edit button — opens Workspace with this preview's data
                      GestureDetector(
                        onTap: () {
                          // TODO: Open WorkspaceScreen with pre-loaded preview
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWhite,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show the contextual options menu
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Options list
            ListTile(
              leading: Icon(Icons.compare_arrows_rounded,
                  color: AppTheme.primaryAccent),
              title: const Text('Compare Before / After'),
              onTap: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompareScreen(preview: preview),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share_outlined,
                  color: AppTheme.primaryAccent),
              title: const Text('Share Preview'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              title: const Text('Delete Preview',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                Navigator.maybePop(context); // Go back after delete
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared glass-style button for the full-screen top bar
// ---------------------------------------------------------------------------
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// Placeholder shown when the wall image URL is null or unavailable
class _PlaceholderWall extends StatelessWidget {
  const _PlaceholderWall();

  @override
  Widget build(BuildContext context) {
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
}
