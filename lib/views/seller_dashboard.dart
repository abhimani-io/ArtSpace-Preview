
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/seller_controller.dart';
import '../models/artwork_model.dart';
import '../utils/app_theme.dart';
import 'seller_drawer.dart';
import 'seller_orders_screen.dart';
import 'seller_customers_screen.dart';
import 'seller_messages_screen.dart';
import 'payouts_screen.dart';
import 'seller_profile_screen.dart';

// ---------------------------------------------------------------------------
// SellerDashboard — ArtSpace Preview
// Admin panel for sellers. Features:
//   - Metrics (Sales, Revenue, Listings)
//   - Upload new artwork to marketplace
//   - Manage listings (View / Delete)
// ---------------------------------------------------------------------------

class SellerDashboard extends StatefulWidget {
  final bool openAddSheet;
  const SellerDashboard({super.key, this.openAddSheet = false});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      final sellerId = auth.firebaseUser?.uid;
      if (sellerId != null) {
        context.read<SellerController>().startListening(sellerId);
      }
      
      if (widget.openAddSheet) {
        _showUploadBottomSheet(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sellerCtrl = context.watch<SellerController>();
    final auth = context.watch<AuthController>();
    final sellerName = auth.firebaseUser?.displayName ?? 'Seller';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundBeige,
      drawer: const SellerDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: AppTheme.textDark),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Seller Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: AppTheme.primaryAccent),
            tooltip: 'Load Mock Data',
            onPressed: () {
              context.read<SellerController>().loadMockData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Mock Data Loaded! Check out the options.'),
                  backgroundColor: AppTheme.primaryAccent,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadBottomSheet(context),
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
        label: const Text('New Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: sellerCtrl.isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent))
          : RefreshIndicator(
              onRefresh: () async {
                final sellerId = auth.firebaseUser?.uid;
                if (sellerId != null) {
                  sellerCtrl.startListening(sellerId);
                }
              },
              color: AppTheme.primaryAccent,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Welcome back, $sellerName',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Metrics
                  _buildMetricsRow(sellerCtrl),
                  const SizedBox(height: 32),

                  Text(
                    'Store Management',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildQuickActionsGrid(context),
                  const SizedBox(height: 32),
                  
                  Text(
                    'My Active Listings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildListingsGrid(sellerCtrl.myListings),
                  const SizedBox(height: 80), // Fab spacing
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _QuickActionCard(
          title: 'Orders',
          icon: Icons.inventory_2_outlined,
          color: Colors.orange,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOrdersScreen())),
        ),
        _QuickActionCard(
          title: 'Customers',
          icon: Icons.people_outline,
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerCustomersScreen())),
        ),
        _QuickActionCard(
          title: 'Messages',
          icon: Icons.chat_bubble_outline,
          color: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerMessagesScreen())),
        ),
        _QuickActionCard(
          title: 'Payouts',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayoutsScreen())),
        ),
        _QuickActionCard(
          title: 'Store Profile',
          icon: Icons.storefront_outlined,
          color: AppTheme.primaryAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerProfileScreen())),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(SellerController ctrl) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Revenue',
            value: '\$${ctrl.totalRevenue.toStringAsFixed(2)}',
            icon: Icons.attach_money_rounded,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Sales',
            value: '${ctrl.totalSales}',
            icon: Icons.shopping_bag_outlined,
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Listings',
            value: '${ctrl.totalListings}',
            icon: Icons.palette_outlined,
            color: AppTheme.primaryAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildListingsGrid(List<ArtworkModel> listings) {
    if (listings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: AppTheme.defaultRadius,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.storefront_outlined, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No active listings',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "New Listing" to add your first artwork.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: listings.length,
      itemBuilder: (_, index) {
        final artwork = listings[index];
        return _ListingCard(
          artwork: artwork,
          onDelete: () => _confirmDelete(artwork),
        );
      },
    );
  }

  void _confirmDelete(ArtworkModel artwork) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        title: Text('Delete Listing?', style: TextStyle(color: AppTheme.textDark)),
        content: Text('Remove "${artwork.name}" from the marketplace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SellerController>().deleteListing(artwork.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showUploadBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UploadListingSheet(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback onDelete;

  const _ListingCard({required this.artwork, required this.onDelete});

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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: artwork.imageUrl.startsWith('http')
                      ? Image.network(
                          artwork.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEFECE6),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
                            ),
                          ),
                        )
                      : Image.memory(
                          base64Decode(artwork.imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEFECE6),
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      artwork.priceLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.shopping_cart_checkout, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${artwork.salesCount}',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// Bottom Sheet for Uploading New Listing
// ---------------------------------------------------------------------------
class _UploadListingSheet extends StatefulWidget {
  const _UploadListingSheet();

  @override
  State<_UploadListingSheet> createState() => _UploadListingSheetState();
}

class _UploadListingSheetState extends State<_UploadListingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dimensionsCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();
  
  final _customCategoryCtrl = TextEditingController();
  final _customSubcategoryCtrl = TextEditingController();
  
  String _selectedCategory = 'Painting'; 
  String _selectedSubcategory = 'Acrylic';
  
  final Map<String, List<String>> _artCategoryMap = {
    'Painting': ['Acrylic', 'Oil', 'Watercolor', 'Gouache', 'Pastel', 'Add Custom...'],
    'Digital Art': ['2D Digital Painting', '3D Modeling', 'Vector Art', 'Pixel Art', 'Add Custom...'],
    'Drawing': ['Charcoal', 'Graphite/Pencil', 'Pen & Ink', 'Colored Pencil', 'Add Custom...'],
    'Photography': ['Portrait', 'Landscape', 'Street', 'Wildlife', 'Add Custom...'],
    'Sculpture': ['Clay', 'Wood', 'Metal', 'Resin', 'Add Custom...'],
    'Mixed Media': ['Collage', 'Assemblage', 'Textile Art', 'Add Custom...'],
    'Add Custom...': ['Add Custom...'],
  };

  Uint8List? _imageBytes;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _dimensionsCtrl.dispose();
    _materialsCtrl.dispose();
    _customCategoryCtrl.dispose();
    _customSubcategoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _submitListing() async {
    print('Upload button pressed. Validating form...');
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed.');
      return;
    }
    
    if (_selectedCategory == 'Add Custom...' && _customCategoryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a custom category'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    if (_selectedSubcategory == 'Add Custom...' && _customSubcategoryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a custom subcategory'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final sellerCtrl = context.read<SellerController>();
    final auth = context.read<AuthController>();
    final sellerName = auth.firebaseUser?.displayName ?? 'Seller';
    final sellerId = auth.firebaseUser!.uid;

    final finalCategory = _selectedCategory == 'Add Custom...' 
        ? _customCategoryCtrl.text.trim() 
        : _selectedCategory;
        
    final finalSubcategory = _selectedSubcategory == 'Add Custom...' 
        ? _customSubcategoryCtrl.text.trim() 
        : _selectedSubcategory;

    final success = await sellerCtrl.uploadArtwork(
      imageBytes: _imageBytes!,
      title: _titleCtrl.text.trim(),
      category: 'Art', // Generic category
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      description: _descCtrl.text.trim(),
      artistName: sellerName,
      sellerId: sellerId,
      dimensions: _dimensionsCtrl.text.trim(),
      materials: _materialsCtrl.text.trim(),
      environmentCategory: finalCategory,
      environmentSubcategory: finalSubcategory,
    );

    if (mounted && success) {
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Artwork published to marketplace!'),
          backgroundColor: AppTheme.primaryAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sellerCtrl.errorMessage ?? 'Upload failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = context.watch<SellerController>().isUploading;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundBeige,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Listing',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                    CloseButton(),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Image Picker
                GestureDetector(
                  onTap: isUploading ? null : _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: AppTheme.defaultRadius,
                      border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              Text('Tap to upload artwork', style: TextStyle(color: AppTheme.textMuted)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildField(
                  controller: _titleCtrl,
                  label: 'Artwork Title',
                  icon: Icons.title,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _dimensionsCtrl,
                        label: 'Dimensions (e.g. 24x36")',
                        icon: Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        controller: _priceCtrl,
                        label: 'Price (USD)',
                        icon: Icons.attach_money,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildField(
                  controller: _materialsCtrl,
                  label: 'Materials (e.g. Oil on Canvas)',
                  icon: Icons.brush,
                ),
                const SizedBox(height: 16),
                
                // Categories
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildDropdown(
                            value: _selectedCategory,
                            items: _artCategoryMap.keys.toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategory = val;
                                  _selectedSubcategory = _artCategoryMap[val]!.first;
                                });
                              }
                            },
                          ),
                          if (_selectedCategory == 'Add Custom...') ...[
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _customCategoryCtrl,
                              label: 'New Category',
                              icon: Icons.category_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildDropdown(
                            value: _selectedSubcategory,
                            items: _artCategoryMap[_selectedCategory]!,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSubcategory = val);
                            },
                          ),
                          if (_selectedSubcategory == 'Add Custom...') ...[
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _customSubcategoryCtrl,
                              label: 'New Subcategory',
                              icon: Icons.subdirectory_arrow_right_outlined,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildField(
                  controller: _descCtrl,
                  label: 'Description',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isUploading ? null : _submitListing,
                    child: isUploading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Publish Listing'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: AppTheme.textDark),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, size: 18, color: AppTheme.textMuted) : null,
        filled: true,
        fillColor: AppTheme.surfaceWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
          style: TextStyle(fontSize: 14, color: AppTheme.textDark),
          items: items.map((c) {
            return DropdownMenuItem(value: c, child: Text(c));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
