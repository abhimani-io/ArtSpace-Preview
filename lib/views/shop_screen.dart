import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../models/artwork_model.dart';
import '../controllers/shop_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/guest_save_modal.dart';
import 'artwork_details_screen.dart';
import 'cart_screen.dart';

// ---------------------------------------------------------------------------
// ShopScreen — ArtSpace E-Commerce Marketplace
// A highly commercial marketplace UI with standard e-commerce elements:
// pricing, cart/buy actions, reviews, stock tags, and standard grid layout.
// ---------------------------------------------------------------------------

// ── Filter maps ────────────────────────────────────────────────────────────

const Map<String, List<String>> _subMap = {
  'All':          [],
  'Abstract':     ['All', 'Geometric', 'Fluid', 'Modern'],
  'Photography':  ['All', 'Landscapes', 'Urban', 'Black & White'],
  'Fine Art':     ['All', 'Oil Paintings', 'Watercolors', 'Classic'],
  'Digital Art':  ['All', '3D Renders', 'Vector Art', 'Illustrations'],
  'Minimalist':   ['All', 'Line Art', 'Simple Shapes', 'Typography'],
};

enum _SortOrder { relevance, priceLow, priceHigh, rating, newest }

// ---------------------------------------------------------------------------
// ShopScreen
// ---------------------------------------------------------------------------
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  _SortOrder _sortOrder = _SortOrder.relevance;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering + Sorting ───────────────────────────────────────────────────

  List<ArtworkModel> get _sortedArtworks {
    var list = List<ArtworkModel>.from(context.watch<ShopController>().filteredArtworks);

    switch (_sortOrder) {
      case _SortOrder.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _SortOrder.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _SortOrder.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOrder.newest:
        list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
        break;
      case _SortOrder.relevance:
        break;
    }
    return list;
  }

  void _setCategory(String cat) {
    context.read<ShopController>().setCategory(cat);
    _fadeCtrl..reset()..forward();
  }

  void _setSub(String sub) {
    context.read<ShopController>().setSubcategory(sub);
    _fadeCtrl..reset()..forward();
  }

  void _toggleWishlist(ArtworkModel item) {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      showGuestSaveModal(context);
      return;
    }
    context.read<ShopController>().toggleFavorite(item);
  }

  void _addToCart(ArtworkModel item) {
    context.read<ShopController>().addToCart(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to Cart!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDetail(ArtworkModel item) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ArtworkDetailsScreen(artwork: item)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final shopCtrl = context.watch<ShopController>();
    final subcategories = _subMap[shopCtrl.selectedCategory] ?? [];
    final items = _sortedArtworks;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Standard clean e-commerce bg
      body: SafeArea(
        child: Column(
          children: [
            // ── Top header (Search & Cart) ────────────────────────────────
            _buildTopBar(),
            const SizedBox(height: 12),
            // ── Categories ─────────────────────────────────────────────────
            _buildCategoryFilter(),
            if (subcategories.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildSubcategoryFilter(subcategories),
            ],
            const SizedBox(height: 12),
            // ── Sort & Result Count ─────────────────────────────────────────
            _buildSortBar(items.length),
            const SizedBox(height: 8),
            // ── Marketplace Grid ───────────────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: items.isEmpty
                    ? _buildEmpty()
                    : _buildGrid(items),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar: Search + Cart ────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          // Search field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => context.read<ShopController>().setSearchQuery(v),
                style: TextStyle(color: AppTheme.textDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle:
                      TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppTheme.textMuted, size: 20),
                  suffixIcon: context.watch<ShopController>().searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              size: 18, color: AppTheme.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            context.read<ShopController>().setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Cart icon with badge
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    size: 28, color: AppTheme.textDark),
                if (context.watch<ShopController>().cart.isNotEmpty)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${context.watch<ShopController>().cart.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category chips ────────────────────────────────────────────────────────

  Widget _buildCategoryFilter() {
    final cats = _subMap.keys.toList();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final sel = context.watch<ShopController>().selectedCategory == cat;
          return GestureDetector(
            onTap: () => _setCategory(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primaryAccent : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel
                        ? AppTheme.primaryAccent
                        : const Color(0xFFE0E0E0)),
              ),
              child: Text(cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppTheme.textDark,
                  )),
            ),
          );
        },
      ),
    );
  }

  // ── Subcategory chips ─────────────────────────────────────────────────────

  Widget _buildSubcategoryFilter(List<String> subs) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: subs.length,
        separatorBuilder: (_, i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final sub = subs[i];
          final sel = context.watch<ShopController>().selectedSubcategory == sub;
          return GestureDetector(
            onTap: () => _setSub(sub),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFF2F2F2) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? const Color(0xFFBDBDBD) : Colors.transparent),
              ),
              child: Text(sub,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? AppTheme.textDark : AppTheme.textMuted,
                  )),
            ),
          );
        },
      ),
    );
  }

  // ── Sort + result count bar ───────────────────────────────────────────────

  Widget _buildSortBar(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count results',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Row(
              children: [
                Text(
                  'Sort by: $_sortLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _sortLabel {
    switch (_sortOrder) {
      case _SortOrder.relevance: return 'Relevance';
      case _SortOrder.priceLow:  return 'Price: Low to High';
      case _SortOrder.priceHigh: return 'Price: High to Low';
      case _SortOrder.rating:    return 'Customer Review';
      case _SortOrder.newest:    return 'Newest Arrivals';
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sort Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            for (final s in _SortOrder.values)
              RadioListTile<_SortOrder>(
                title: Text(_sortName(s)),
                value: s,
                groupValue: _sortOrder,
                activeColor: AppTheme.primaryAccent,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sortOrder = val);
                    Navigator.pop(context);
                    _fadeCtrl..reset()..forward();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _sortName(_SortOrder s) {
    switch (s) {
      case _SortOrder.relevance: return 'Relevance';
      case _SortOrder.priceLow:  return 'Price: Low to High';
      case _SortOrder.priceHigh: return 'Price: High to Low';
      case _SortOrder.rating:    return 'Customer Review';
      case _SortOrder.newest:    return 'Newest Arrivals';
    }
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No products matched your search',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              final ctrl = context.read<ShopController>();
              ctrl.setSearchQuery('');
              ctrl.setCategory('All');
              ctrl.setSubcategory('All');
            },
            child: const Text('Clear Filters',
                style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  // ── Product grid ──────────────────────────────────────────────────────────

  Widget _buildGrid(List<ArtworkModel> items) {
    final favoriteIds = context.watch<ShopController>().favoriteIds;
    // Marketplace styled cards in a masonry grid to show full uncropped art
    return MasonryGridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      itemCount: items.length,
      itemBuilder: (_, index) => _CommerceCard(
        item: items[index],
        isWishlisted: favoriteIds.contains(items[index].id),
        onWishlist: () => _toggleWishlist(items[index]),
        onTap: () => _openDetail(items[index]),
        onAddToCart: () => _addToCart(items[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CommerceCard — E-Commerce style product card
// ---------------------------------------------------------------------------
class _CommerceCard extends StatelessWidget {
  final ArtworkModel item;
  final bool isWishlisted;
  final VoidCallback onWishlist;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const _CommerceCard({
    required this.item,
    required this.isWishlisted,
    required this.onWishlist,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Section (Full Aspect Ratio) ──────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    child: item.isLocalAsset 
                      ? Image.asset(
                          item.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        )
                      : (item.imageUrl.startsWith('http') 
                          ? Image.network(
                              item.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Image.memory(
                              base64Decode(item.imageUrl),
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )),
                  ),
                ),
                // Wishlist Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onWishlist,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isWishlisted ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // ── Commerce Info ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand / Artist
                    Text(
                      item.artistName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Product Title
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Ratings
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < (item.rating > 0 ? item.rating.floor() : 5) ? Icons.star : Icons.star_border,
                            size: 14,
                            color: AppTheme.textDark,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '${item.reviewCount > 0 ? item.reviewCount : 12}',
                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Price
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Stock Status
                    const Text(
                      '1 of 1 Original',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC62828), // Deep Red for exclusivity
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Action Buttons (Add to Cart + AR)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryAccent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text('Add to Cart',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // AR / Try On Button
                        OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(36, 36),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Icon(Icons.view_in_ar_outlined, size: 18, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
