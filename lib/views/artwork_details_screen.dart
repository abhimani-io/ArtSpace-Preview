import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/artwork_model.dart';
import '../controllers/shop_controller.dart';
import '../controllers/workspace_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/guest_save_modal.dart';
import '../controllers/auth_controller.dart';
import 'workspace_screen.dart';
import 'custom_camera_screen.dart';

// ---------------------------------------------------------------------------
// ArtworkDetailsScreen — ArtSpace Preview
// Detailed view of an artwork showing high-res image and metadata.
// Includes triggers for "Favorite" and "Add to Wall".
// ---------------------------------------------------------------------------

class ArtworkDetailsScreen extends StatefulWidget {
  final ArtworkModel artwork;
  // True when the user arrived here after capturing a wall photo with the camera.
  // Controls whether "Add to Wall" skips the source dialog and goes directly
  // to WorkspaceScreen using the already-captured wall image.
  final bool isFromCamera;
  final bool isArtHuntMode;

  const ArtworkDetailsScreen({
    super.key,
    required this.artwork,
    this.isFromCamera = false,
    this.isArtHuntMode = false,
  });

  @override
  State<ArtworkDetailsScreen> createState() => _ArtworkDetailsScreenState();
}

class _ArtworkDetailsScreenState extends State<ArtworkDetailsScreen> {
  void _toggleFavorite() {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      showGuestSaveModal(context);
      return;
    }
    context.read<ShopController>().toggleFavorite(widget.artwork);
  }

  // ---------------------------------------------------------------------------
  // "Add to Wall" handler — behaviour depends on isFromCamera flag
  // ---------------------------------------------------------------------------
  void _onAddToWall() {
    if (widget.isFromCamera) {
      // Scenario 1: User came from the camera flow.
      // The wall photo is already captured and stored in WorkspaceController.
      // Skip the source dialog and go straight to WorkspaceScreen.
      _proceedToWorkspaceWithCapturedWall();
    } else {
      // Scenario 2: User came from the catalog/home directly.
      // Show the "Live AR Camera / Choose from Gallery" dialog.
      _showWallSourceSheet();
    }
  }

  /// Navigates directly to WorkspaceScreen using the already-captured wall
  /// photo stored in [WorkspaceController]. Called only when isFromCamera=true.
  void _proceedToWorkspaceWithCapturedWall() {
    final workspaceCtrl = context.read<WorkspaceController>();
    final art = widget.artwork;

    // Register the selected artwork in the controller.
    if (!art.isLocalAsset) {
      workspaceCtrl.setSelectedMarketplaceArtwork(
        artworkId: art.id,
        networkUrl: art.imageUrl,
      );
    }

    if (workspaceCtrl.wallImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wall photo not found. Please retake the photo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkspaceScreen(
          wallImageBytes: workspaceCtrl.wallImageBytes,
          // Route to the right image source based on artwork origin
          artworkAssetPath: art.isLocalAsset ? art.imageUrl : null,
          artworkNetworkUrl: art.isLocalAsset ? null : art.imageUrl,
          artworkId: art.isLocalAsset ? null : art.id,
        ),
      ),
    );
  }

  /// Shows the bottom sheet with "Live AR Camera" / "Choose from Gallery"
  /// options. Called only when isFromCamera=false.
  void _showWallSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Select Wall Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryAccent),
              title: const Text('Live AR Preview', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _handleWallCapture(isCamera: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: AppTheme.primaryAccent),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _handleWallCapture(isCamera: false);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _handleWallCapture({required bool isCamera}) async {
    final workspaceCtrl = context.read<WorkspaceController>();
    final art = widget.artwork;

    if (!art.isLocalAsset) {
      workspaceCtrl.setSelectedMarketplaceArtwork(
        artworkId: art.id,
        networkUrl: art.imageUrl,
      );
    }

    if (isCamera) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomCameraScreen(
            originSource: 'art_hunt',
            preselectedArtwork: art,
          ),
        ),
      );
    } else {
      final success = await workspaceCtrl.pickWallFromGallery();
      if (!mounted) return;

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkspaceScreen(
              wallImageBytes: workspaceCtrl.wallImageBytes,
              artworkAssetPath: art.isLocalAsset ? art.imageUrl : null,
              artworkNetworkUrl: art.isLocalAsset ? null : art.imageUrl,
              artworkId: art.isLocalAsset ? null : art.id,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access gallery.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // For local asset artworks, skip ShopController lookup (they are not in Firestore).
    // For network artworks, sync favourite state from ShopController.
    final shopCtrl = context.watch<ShopController>();
    final currentArtwork = widget.artwork.isLocalAsset
        ? widget.artwork
        : shopCtrl.artworks.firstWhere(
            (a) => a.id == widget.artwork.id,
            orElse: () => widget.artwork,
          );

    // Helper: build the correct image widget based on artwork origin
    Widget artworkHeroImage() {
      if (currentArtwork.isLocalAsset) {
        return Image.asset(
          currentArtwork.imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, e, s) => Container(
            color: AppTheme.surfaceWhite,
            child: const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 48),
            ),
          ),
        );
      }
      return currentArtwork.imageUrl.startsWith('http')
          ? Image.network(
              currentArtwork.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                color: AppTheme.surfaceWhite,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 48),
                ),
              ),
            )
          : Image.memory(
              base64Decode(currentArtwork.imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                color: AppTheme.surfaceWhite,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 48),
                ),
              ),
            );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400.0,
            pinned: true,
            backgroundColor: AppTheme.backgroundBeige,
            iconTheme: IconThemeData(color: AppTheme.textDark),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Hero(
                  tag: 'artwork_${currentArtwork.id}',
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: artworkHeroImage(),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentArtwork.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: currentArtwork.isFavorite ? Colors.redAccent : AppTheme.textDark,
                    size: 22,
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentArtwork.name,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'By ${currentArtwork.artistName}',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Dynamic Ratings UI
                            if (currentArtwork.reviewCount > 0)
                              Row(
                                children: [
                                  ...List.generate(5, (i) {
                                    return Icon(
                                      i < currentArtwork.rating.round() ? Icons.star : Icons.star_border,
                                      size: 18,
                                      color: AppTheme.textDark,
                                    );
                                  }),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${currentArtwork.rating} (${currentArtwork.reviewCount} reviews)',
                                    style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'No reviews yet',
                                style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                      ),
                      if (currentArtwork.price > 0)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${currentArtwork.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'In Stock',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF388E3C), // Green
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Dimensions', currentArtwork.dimensions.isNotEmpty ? currentArtwork.dimensions : 'Not specified'),
                  _buildDetailRow('Materials', currentArtwork.materials.isNotEmpty ? currentArtwork.materials : 'Not specified'),
                  _buildDetailRow('Environment', '${currentArtwork.environmentCategory} • ${currentArtwork.environmentSubcategory}'),
                  const SizedBox(height: 32),
                  if (currentArtwork.description.isNotEmpty) ...[
                    Text('About this piece', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    Text(
                      currentArtwork.description,
                      style: TextStyle(fontSize: 15, color: AppTheme.textMuted, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 100), // padding for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          boxShadow: [
            BoxShadow(
              color: AppTheme.textDark.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: widget.isArtHuntMode
              ? [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onAddToWall,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.view_in_ar_outlined, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Add to Wall', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      context.read<ShopController>().addToCart(currentArtwork);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to Cart!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: const Color(0xFF2E7D32),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: const BorderSide(color: Colors.grey, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Icon(Icons.shopping_cart_outlined, color: AppTheme.textDark),
                  ),
                ]
              : [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<ShopController>().addToCart(currentArtwork);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Added to Cart!'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: const Color(0xFF2E7D32),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _onAddToWall,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: const BorderSide(color: Colors.grey, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Icon(Icons.view_in_ar_outlined, color: AppTheme.textDark),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: AppTheme.textDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
