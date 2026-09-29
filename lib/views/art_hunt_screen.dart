import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../controllers/shop_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/premium_frame.dart';
import 'artwork_details_screen.dart';
import '../models/artwork_model.dart';
// ---------------------------------------------------------------------------
// ArtHuntScreen — ArtSpace Preview
// Displays local asset images in a beautiful framed grid, filtered by
// main category and sub-category (multi-level filter chips).
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Data Model: local asset artwork entry
// ---------------------------------------------------------------------------
class LocalArtwork {
  final String assetPath;
  final String name;
  final String category;
  final String subcategory;
  final double price;
  final String description;

  const LocalArtwork({
    required this.assetPath,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.description,
  });
}

// ---------------------------------------------------------------------------
// Asset Catalogue — every image mapped to its category & subcategory
// ---------------------------------------------------------------------------
const List<LocalArtwork> localArtworkCatalogue = [
  // Abstract
  LocalArtwork(assetPath: 'assets/images/bedroom1.jpg',    name: 'Neon Geometry',       category: 'Abstract',    subcategory: 'Geometric', price: 450.0, description: 'An exclusive 1-of-1 exploration of light and form.'),
  LocalArtwork(assetPath: 'assets/images/bedroom2.jpg',    name: 'Fluid Dynamics',      category: 'Abstract',    subcategory: 'Fluid', price: 850.0, description: 'A singular piece capturing the essence of motion.'),
  LocalArtwork(assetPath: 'assets/images/bedroom3.jpg',    name: 'Modern Clash',        category: 'Abstract',    subcategory: 'Modern', price: 1200.0, description: 'A unique clash of modern colors, original piece.'),
  LocalArtwork(assetPath: 'assets/images/bedroom4.jpg',    name: 'Golden Ratio',        category: 'Abstract',    subcategory: 'Geometric', price: 1500.0, description: 'The only one of its kind, mathematically perfect.'),
  // Photography
  LocalArtwork(assetPath: 'assets/images/hkitchen1.jpg',   name: 'Misty Mountains',     category: 'Photography', subcategory: 'Landscapes', price: 2400.0, description: 'A rare morning capture, one of one print.'),
  LocalArtwork(assetPath: 'assets/images/hkitchen2.jpg',   name: 'Neon Cityscape',      category: 'Photography', subcategory: 'Urban', price: 3200.0, description: 'Original exposure from the heart of the city.'),
  LocalArtwork(assetPath: 'assets/images/hkitchen3.jpg',   name: 'Noir Shadows',        category: 'Photography', subcategory: 'Black & White', price: 5000.0, description: 'Unique silver gelatin print, never reproduced.'),
  LocalArtwork(assetPath: 'assets/images/hkitchen4.jpg',   name: 'Sunset Ridge',        category: 'Photography', subcategory: 'Landscapes', price: 450.0, description: 'A singular moment in time, captured forever.'),
  // Fine Art
  LocalArtwork(assetPath: 'assets/images/livingroom1.jpg', name: 'Classic Still Life',  category: 'Fine Art',    subcategory: 'Oil Paintings', price: 850.0, description: 'Original oil on canvas, 1-of-1.'),
  LocalArtwork(assetPath: 'assets/images/livingroom2.jpg', name: 'Riverside Watercolor', category: 'Fine Art',   subcategory: 'Watercolors', price: 1200.0, description: 'Original watercolor, one piece available.'),
  LocalArtwork(assetPath: 'assets/images/livingroom3.jpg', name: 'The Grand Epoch',     category: 'Fine Art',    subcategory: 'Classic', price: 1500.0, description: 'A masterpiece of classic proportions, original.'),
  LocalArtwork(assetPath: 'assets/images/livingroom4.jpg', name: 'Portrait in Oil',     category: 'Fine Art',    subcategory: 'Oil Paintings', price: 2400.0, description: 'An intimate original portrait, 1-of-1.'),
  // Digital Art
  LocalArtwork(assetPath: 'assets/images/rkitchen1.jpg',   name: 'Chrome Sphere',       category: 'Digital Art', subcategory: '3D Renders', price: 3200.0, description: 'Exclusive 1-of-1 digital render.'),
  LocalArtwork(assetPath: 'assets/images/rkitchen2.jpg',   name: 'Vector Horizon',      category: 'Digital Art', subcategory: 'Vector Art', price: 5000.0, description: 'Original vector composition, no copies.'),
  LocalArtwork(assetPath: 'assets/images/rkitchen3.jpg',   name: 'Cyberpunk Illust',    category: 'Digital Art', subcategory: 'Illustrations', price: 450.0, description: 'One-of-a-kind digital illustration.'),
  LocalArtwork(assetPath: 'assets/images/rkitchen4.jpg',   name: 'Abstract 3D',         category: 'Digital Art', subcategory: '3D Renders', price: 850.0, description: 'Unique 3D scene, rendered once.'),
  // Minimalist
  LocalArtwork(assetPath: 'assets/images/cdinning1.jpg',   name: 'Single Line Face',    category: 'Minimalist',  subcategory: 'Line Art', price: 1200.0, description: 'A continuous original line drawing.'),
  LocalArtwork(assetPath: 'assets/images/cdinning2.jpg',   name: 'Circle & Square',     category: 'Minimalist',  subcategory: 'Simple Shapes', price: 1500.0, description: 'The only original copy of this study.'),
  LocalArtwork(assetPath: 'assets/images/cdinning3.jpg',   name: 'Breathe Type',        category: 'Minimalist',  subcategory: 'Typography', price: 2400.0, description: 'Original typographical layout, 1-of-1.'),
  LocalArtwork(assetPath: 'assets/images/cdinning4.jpg',   name: 'Abstract Line',       category: 'Minimalist',  subcategory: 'Line Art', price: 3200.0, description: 'A rare minimalist original.'),
  // More mixed
  LocalArtwork(assetPath: 'assets/images/cafe1.jpg',       name: 'Fluid Thought',       category: 'Abstract',    subcategory: 'Fluid', price: 5000.0, description: 'A singular expression of fluidity.'),
  LocalArtwork(assetPath: 'assets/images/cafe2.jpg',       name: 'Urban Grime',         category: 'Photography', subcategory: 'Urban', price: 450.0, description: 'Unique urban capture, original print.'),
  LocalArtwork(assetPath: 'assets/images/cafe3.jpg',       name: 'Vintage Still',       category: 'Fine Art',    subcategory: 'Classic', price: 850.0, description: 'An original classic composition.'),
  LocalArtwork(assetPath: 'assets/images/cafe4.jpg',       name: 'Poly World',          category: 'Digital Art', subcategory: '3D Renders', price: 1200.0, description: 'Exclusive 1-of-1 poly render.'),
  LocalArtwork(assetPath: 'assets/images/primary1.jpg',    name: 'Shape Shift',         category: 'Minimalist',  subcategory: 'Simple Shapes', price: 1500.0, description: 'Original geometric study.'),
  LocalArtwork(assetPath: 'assets/images/primary2.jpg',    name: 'Forest Path',         category: 'Photography', subcategory: 'Landscapes', price: 2400.0, description: 'A rare capture of nature, 1-of-1.'),
  LocalArtwork(assetPath: 'assets/images/primary3.jpg',    name: 'Modern Mind',         category: 'Abstract',    subcategory: 'Modern', price: 3200.0, description: 'A singular abstract vision.'),
  LocalArtwork(assetPath: 'assets/images/primary4.jpg',    name: 'Focus',               category: 'Minimalist',  subcategory: 'Typography', price: 5000.0, description: 'Original typographic art piece.'),
  LocalArtwork(assetPath: 'assets/images/staff1.jpg',      name: 'Oil Sunrise',         category: 'Fine Art',    subcategory: 'Oil Paintings', price: 450.0, description: 'One original oil canvas.'),
  LocalArtwork(assetPath: 'assets/images/staff2.jpg',      name: 'Digital Dream',       category: 'Digital Art', subcategory: 'Illustrations', price: 850.0, description: 'A unique digital dreamscape.'),
  LocalArtwork(assetPath: 'assets/images/staff3.jpg',      name: 'B&W Street',          category: 'Photography', subcategory: 'Black & White', price: 1200.0, description: 'Original black and white exposure.'),
  LocalArtwork(assetPath: 'assets/images/staff4.jpg',      name: 'Geometric Sun',       category: 'Abstract',    subcategory: 'Geometric', price: 1500.0, description: 'A singular geometric creation.'),
  LocalArtwork(assetPath: 'assets/images/library1.jpg',    name: 'Watercolor Spring',   category: 'Fine Art',    subcategory: 'Watercolors', price: 2400.0, description: 'Original watercolor landscape, 1-of-1.'),
  LocalArtwork(assetPath: 'assets/images/library2.jpg',    name: 'Vector Town',         category: 'Digital Art', subcategory: 'Vector Art', price: 3200.0, description: 'Exclusive vector art piece.'),
  LocalArtwork(assetPath: 'assets/images/library3.jpg',    name: 'Line Woman',          category: 'Minimalist',  subcategory: 'Line Art', price: 5000.0, description: 'An original continuous line piece.'),
  LocalArtwork(assetPath: 'assets/images/library4.jpg',    name: 'Fluid Wave',          category: 'Abstract',    subcategory: 'Fluid', price: 450.0, description: 'One original fluid painting.'),
  LocalArtwork(assetPath: 'assets/images/odinning1.jpg',   name: 'Classic Manor',       category: 'Fine Art',    subcategory: 'Classic', price: 850.0, description: 'A rare classic original.'),
  LocalArtwork(assetPath: 'assets/images/odinning2.jpg',   name: 'Urban Night',         category: 'Photography', subcategory: 'Urban', price: 1200.0, description: 'Unique nighttime exposure.'),
  LocalArtwork(assetPath: 'assets/images/odinning3.jpg',   name: 'Modern Chaos',        category: 'Abstract',    subcategory: 'Modern', price: 1500.0, description: 'An original abstract piece.'),
  LocalArtwork(assetPath: 'assets/images/conference2.jpg', name: '3D Cube',             category: 'Digital Art', subcategory: '3D Renders', price: 2400.0, description: 'Exclusive 1-of-1 render.'),
  LocalArtwork(assetPath: 'assets/images/lobby1.jpg',      name: 'Bold Type',           category: 'Minimalist',  subcategory: 'Typography', price: 3200.0, description: 'Original bold typography.'),
  LocalArtwork(assetPath: 'assets/images/lobby2.jpg',      name: 'B&W Portrait',        category: 'Photography', subcategory: 'Black & White', price: 5000.0, description: 'A rare original portrait.'),
];

// ---------------------------------------------------------------------------
// Category icon map
// ---------------------------------------------------------------------------
const Map<String, IconData> _categoryIcons = {
  'All':          Icons.apps_rounded,
  'Abstract':     Icons.category_rounded,
  'Photography':  Icons.camera_alt_rounded,
  'Fine Art':     Icons.brush_rounded,
  'Digital Art':  Icons.computer_rounded,
  'Minimalist':   Icons.crop_square_rounded,
};

// ---------------------------------------------------------------------------
// Sub-category map (used to populate the second filter row)
// ---------------------------------------------------------------------------
const Map<String, List<String>> _subMap = {
  'All':          [],
  'Abstract':     ['All', 'Geometric', 'Fluid', 'Modern'],
  'Photography':  ['All', 'Landscapes', 'Urban', 'Black & White'],
  'Fine Art':     ['All', 'Oil Paintings', 'Watercolors', 'Classic'],
  'Digital Art':  ['All', '3D Renders', 'Vector Art', 'Illustrations'],
  'Minimalist':   ['All', 'Line Art', 'Simple Shapes', 'Typography'],
};

// ---------------------------------------------------------------------------
// Screen Widget
// ---------------------------------------------------------------------------
class ArtHuntScreen extends StatefulWidget {
  /// True when user arrived from the camera capture flow.
  /// Passed down to ArtworkDetailsScreen to control "Add to Wall" behaviour.
  final bool isFromCamera;

  const ArtHuntScreen({super.key, this.isFromCamera = false});

  @override
  State<ArtHuntScreen> createState() => _ArtHuntScreenState();
}

class _ArtHuntScreenState extends State<ArtHuntScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _selectedSubcategory = 'All';
  String _searchQuery = '';

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnimation;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering logic ───────────────────────────────────────────────────────

  List<LocalArtwork> get _filtered {
    return localArtworkCatalogue.where((art) {
      final matchCat = _selectedCategory == 'All' ||
          art.category == _selectedCategory;
      final matchSub = _selectedSubcategory == 'All' ||
          art.subcategory == _selectedSubcategory;
      final matchSearch = _searchQuery.isEmpty ||
          art.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          art.subcategory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          art.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSub && matchSearch;
    }).toList();
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _selectedSubcategory = 'All'; // reset sub-filter on main change
    });
    _fadeCtrl
      ..reset()
      ..forward();
  }

  void _selectSubcategory(String sub) {
    setState(() => _selectedSubcategory = sub);
    _fadeCtrl
      ..reset()
      ..forward();
  }

  // ── Navigate to detail screen ─────────────────────────────────────────────

  void _openDetail(LocalArtwork art) {
    final isFav = context.read<ShopController>().favoriteIds.contains(art.assetPath);
    final model = ArtworkModel(
      id: art.assetPath,
      imageUrl: art.assetPath,
      name: art.name,
      category: art.category,
      isFavorite: isFav,
      uploadedAt: DateTime.now(),
      price: art.price,
      artistName: 'Verified Artist',
      description: art.description,
      isPurchasable: true,
      environmentCategory: art.category,
      environmentSubcategory: art.subcategory,
      dimensions: '',
      materials: '',
      isLocalAsset: true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtworkDetailsScreen(
          artwork: model,
          isFromCamera: widget.isFromCamera,
          isArtHuntMode: true,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final subcategories = _subMap[_selectedCategory] ?? [];
    final displayList = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildSearchBar(),
            const SizedBox(height: 14),
            _buildCategoryFilter(),
            if (subcategories.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildSubcategoryFilter(subcategories),
            ],
            const SizedBox(height: 6),
            _buildResultCount(displayList.length),
            const SizedBox(height: 6),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildGrid(displayList),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Color(0xFF3E2723)),
            ),
          ),

          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Artwork',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3E2723),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  _selectedCategory == 'All'
                      ? 'All categories'
                      : _selectedSubcategory == 'All'
                          ? _selectedCategory
                          : '$_selectedCategory › $_selectedSubcategory',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D6E63),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Camera/gallery indicator badge
          if (widget.isFromCamera)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt_rounded,
                      size: 12, color: AppTheme.primaryAccent),
                  SizedBox(width: 4),
                  Text(
                    'Camera',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(
            color: Color(0xFF3E2723),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Search rooms or categories…',
            hintStyle: const TextStyle(color: Color(0xFF8D6E63), fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Color(0xFF8D6E63), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        size: 18, color: Color(0xFF8D6E63)),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ── Level-1 category chips ────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    final categories = _subMap.keys.toList();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final selected = _selectedCategory == cat;
          final icon = _categoryIcons[cat] ?? Icons.category_rounded;
          return GestureDetector(
            onTap: () => _selectCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF5D4037)
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF5D4037)
                      : const Color(0xFFD7CCC8),
                  width: 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF5D4037).withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF8D6E63)),
                  const SizedBox(width: 6),
                  Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF8D6E63),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Level-2 subcategory chips ─────────────────────────────────────────────

  Widget _buildSubcategoryFilter(List<String> subs) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: subs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final sub = subs[i];
          final selected = _selectedSubcategory == sub;
          return GestureDetector(
            onTap: () => _selectSubcategory(sub),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFBCAAA4)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF8D6E63)
                      : const Color(0xFFBCAAA4),
                  width: 1.2,
                ),
              ),
              child: Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF3E2723)
                      : const Color(0xFF8D6E63),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Result count ──────────────────────────────────────────────────────────

  Widget _buildResultCount(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '$count artwork${count == 1 ? '' : 's'} found',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8D6E63),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  Widget _buildGrid(List<LocalArtwork> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search_rounded,
                size: 56, color: Colors.brown.shade200),
            const SizedBox(height: 12),
            const Text(
              'No artworks found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8D6E63),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different category or search term.',
              style: TextStyle(fontSize: 12, color: Color(0xFFBCAAA4)),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: 28,
      crossAxisSpacing: 20,
      itemCount: items.length,
      itemBuilder: (_, index) => _ArtworkCard(
        artwork: items[index],
        onTap: () => _openDetail(items[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ArtworkCard — individual card with 3D wooden frame effect
// ---------------------------------------------------------------------------
class _ArtworkCard extends StatefulWidget {
  final LocalArtwork artwork;
  final VoidCallback onTap;

  const _ArtworkCard({required this.artwork, required this.onTap});

  @override
  State<_ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<_ArtworkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.03,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          children: [
            // ── Framed artwork image ─────────────────────────────────────
            PremiumFrame(
              child: Image.asset(
                widget.artwork.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  color: const Color(0xFFEFEBE9),
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFFBCAAA4),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Label below frame ────────────────────────────────────────
            Text(
              widget.artwork.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4E342E),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              '\$${widget.artwork.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFC62828), // Deep red to denote exclusivity
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

