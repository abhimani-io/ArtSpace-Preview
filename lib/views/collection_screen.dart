import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/collection_controller.dart';
import '../controllers/workspace_controller.dart';
import '../controllers/shop_controller.dart';
import '../models/artwork_model.dart';
import '../models/purchased_art_model.dart';
import '../models/preview_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'workspace_screen.dart';
import 'preview_fullscreen.dart';
import 'select_artwork_screen.dart';
import 'art_hunt_screen.dart';

// ---------------------------------------------------------------------------
// CollectionScreen — ArtSpace Preview
// Two-tab layout:
//   Tab 0: Saved Previews  — composite wall+artwork images the user saved
//   Tab 1: Purchased Art   — officially purchased artworks
// ---------------------------------------------------------------------------

class CollectionScreen extends StatefulWidget {
  final bool showOnlyFavorites;
  final int initialTabIndex;

  const CollectionScreen({
    super.key,
    this.showOnlyFavorites = false,
    this.initialTabIndex = 0,
  });

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _categories = [
    'All', 'Abstract', 'Photography', 'Fine Art', 'Digital Art', 'Minimalist'
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    context.read<CollectionController>().startListening();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBeige,
        body: SafeArea(
          child: _buildUnauthenticatedState(context),
        ),
      );
    }

    final controller = context.watch<CollectionController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 16),

            // Tab Bar
            _buildTabBar(),
            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SavedPreviewsTab(categories: _categories),
                  _PurchasedArtTab(purchases: controller.purchases),
                  _FavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Collection',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your saved previews & purchased artworks',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.premiumShadow,
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppTheme.primaryAccent,
            borderRadius: BorderRadius.circular(10),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textMuted,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Saved Previews'),
            Tab(text: 'Purchased Art'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: AppTheme.primaryAccent,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Private Stash',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to access your saved previews, track your purchased artworks, and manage your favorites.',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Login to Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 0 — Saved Previews
// ---------------------------------------------------------------------------
class _SavedPreviewsTab extends StatefulWidget {
  final List<String> categories;

  const _SavedPreviewsTab({required this.categories});

  @override
  State<_SavedPreviewsTab> createState() => _SavedPreviewsTabState();
}

class _SavedPreviewsTabState extends State<_SavedPreviewsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<PreviewModel> _previews = [];

  @override
  void initState() {
    super.initState();
    _listenPreviews();
  }

  void _listenPreviews() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_previews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      if (mounted) {
        setState(() {
          _previews = snap.docs.map((doc) => PreviewModel.fromFirestore(doc)).toList();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_previews.isEmpty) return _buildEmptyState();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: _previews.length,
      itemBuilder: (_, index) => _PreviewCard(
        preview: _previews[index],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreviewFullScreen(
              preview: _previews[index],
              imageUrl: _previews[index].thumbnailUrl ?? '',
            ),
          ),
        ),
        onDelete: () => _confirmDelete(_previews[index].id),
        onBuy: _previews[index].hasPurchasableArtwork
            ? () => _buyArtwork(_previews[index])
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 60,
              color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'No previews saved yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the AR preview to create your first wall preview',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _buyArtwork(PreviewModel preview) async {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    // Fetch artwork details from Firestore
    final artwork = await context
        .read<FirestoreService>()
        .getPublicArtwork(preview.artworkId!);
    if (!mounted || artwork == null) return;

    context.read<ShopController>().addToCart(artwork);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _confirmDelete(String previewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Preview',
            style: TextStyle(color: AppTheme.textDark)),
        content: Text('This preview will be permanently removed.',
            style: TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FirestoreService>().deletePreview(previewId);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Purchased Art
// ---------------------------------------------------------------------------
class _PurchasedArtTab extends StatelessWidget {
  final List<PurchasedArtModel> purchases;

  const _PurchasedArtTab({required this.purchases});

  @override
  Widget build(BuildContext context) {
    if (purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 60,
                color: AppTheme.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No purchased artworks yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Browse the Shop to find artworks you love',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: purchases.length,
      itemBuilder: (_, index) => _PurchasedArtCard(purchase: purchases[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Favorites
// ---------------------------------------------------------------------------
class _FavoritesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final shopCtrl = context.watch<ShopController>();
    
    // Firestore favorites
    final firestoreFavorites = shopCtrl.artworks.where((a) => a.isFavorite).toList();
    
    // Local asset favorites
    final localFavorites = localArtworkCatalogue
        .where((art) => shopCtrl.favoriteIds.contains(art.assetPath))
        .map((art) => ArtworkModel(
              id: art.assetPath,
              imageUrl: art.assetPath,
              name: art.name,
              category: art.category,
              isFavorite: true,
              uploadedAt: DateTime.now(),
              price: 0,
              artistName: 'Mock Artist',
              isPurchasable: false,
              environmentCategory: art.category,
              environmentSubcategory: art.subcategory,
              dimensions: '',
              materials: '',
              isLocalAsset: true,
            ))
        .toList();

    final favorites = [...firestoreFavorites, ...localFavorites];

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 60,
                color: AppTheme.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Heart artworks in the marketplace to save them here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: favorites.length,
      itemBuilder: (_, index) {
        final art = favorites[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    art.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      art.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      art.artistName,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _PreviewCard — card in the Saved Previews grid
// ---------------------------------------------------------------------------
class _PreviewCard extends StatelessWidget {
  final PreviewModel preview;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onBuy;

  const _PreviewCard({
    required this.preview,
    required this.onTap,
    required this.onDelete,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final String? thumb = preview.thumbnailUrl;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: AppTheme.smallRadius,
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: thumb != null
                        ? (thumb.startsWith('http')
                            ? Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => _placeholder())
                            : Image.asset(
                                thumb,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => _placeholder()))
                        : _placeholder(),
                  ),
                  // Options menu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showOptions(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.more_vert,
                            size: 16, color: AppTheme.textDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title + date
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(preview.formattedDate,
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            // Buy button (only if artwork is purchasable)
            if (onBuy != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined,
                            size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Buy this Artwork',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEFECE6),
      child: Center(
          child: Icon(Icons.image_outlined,
              size: 40, color: AppTheme.textMuted)),
    );
  }

  void _showOptions(BuildContext context) {
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
            ListTile(
              leading: Icon(Icons.open_in_full_rounded,
                  color: AppTheme.primaryAccent),
              title: const Text('View Full Screen'),
              onTap: () {
                Navigator.pop(context);
                onTap();
              },
            ),
            if (onBuy != null)
              ListTile(
                leading: Icon(Icons.shopping_bag_outlined,
                    color: AppTheme.primaryAccent),
                title: const Text('Buy this Artwork'),
                onTap: () {
                  Navigator.pop(context);
                  onBuy!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              title: const Text('Delete Preview',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
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
// _PurchasedArtCard — card in the Purchased Art grid
// ---------------------------------------------------------------------------
class _PurchasedArtCard extends StatelessWidget {
  final PurchasedArtModel purchase;

  const _PurchasedArtCard({required this.purchase});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.smallRadius,
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    purchase.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFEFECE6),
                      child: Center(
                          child: Icon(Icons.image_outlined,
                              color: AppTheme.textMuted, size: 36)),
                    ),
                  ),
                ),
                // "Owned" badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.white, size: 11),
                        SizedBox(width: 3),
                        Text('Owned',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purchase.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${purchase.artistName.isNotEmpty ? purchase.artistName : "Unknown"}',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(purchase.priceLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryAccent,
                        )),
                    Text(purchase.formattedDate,
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
