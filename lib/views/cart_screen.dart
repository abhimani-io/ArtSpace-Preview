import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/shop_controller.dart';
import '../models/artwork_model.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import 'collection_screen.dart';

// ---------------------------------------------------------------------------
// CartScreen — ArtSpace E-Commerce
// Displays cart items, takes shipping & customer details, and processes payment.
// ---------------------------------------------------------------------------

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {

  
  // Customer Details
  final _emailController = TextEditingController(text: 'john@example.com');
  final _phoneController = TextEditingController(text: '+1 234 567 8900');
  final _addressController = TextEditingController(text: '123 Art Lane, NY 10001');

  final _formKey = GlobalKey<FormState>();

  late AnimationController _successAnimCtrl;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _successAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {

    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _successAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeCheckout() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final shopCtrl = context.read<ShopController>();
    final amount = shopCtrl.cartTotal + (shopCtrl.cartTotal * 0.08); // total with tax
    final orderId = DateTime.now().millisecondsSinceEpoch.toString();

    PaymentService.startPayherePayment(
      amount: amount,
      orderId: orderId,
      onSuccess: (paymentId) async {
        if (!mounted) return;
        
        final success = await shopCtrl.checkoutCart();
        if (!mounted) return;

        if (success) {
          setState(() => _showSuccess = true);
          _successAnimCtrl.forward();
          await Future.delayed(const Duration(milliseconds: 2200));
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const CollectionScreen(initialTabIndex: 1),
            ),
            (route) => route.isFirst,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(shopCtrl.errorMessage ?? 'Failed to record purchase.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: $error'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onDismissed: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Cancelled.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopCtrl = context.watch<ShopController>();
    final cartItems = shopCtrl.cart;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBeige,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppTheme.textDark),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Cart & Checkout'),
        centerTitle: true,
      ),
      body: _showSuccess
          ? _buildSuccessOverlay()
          : cartItems.isEmpty
              ? _buildEmptyCart()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Cart Items ---
                        _buildSectionTitle('Your Items'),
                        const SizedBox(height: 14),
                        ...cartItems.map((item) => _buildCartItemCard(item, shopCtrl)),
                        const SizedBox(height: 16),

                        // --- Customer Details ---
                        _buildSectionTitle('Shipping Details'),
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'your@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: '+1 234 567 8900',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _buildInputField(
                          controller: _addressController,
                          label: 'Shipping Address',
                          hint: '123 Main St, City, Zip',
                          icon: Icons.local_shipping_outlined,
                        ),
                        const SizedBox(height: 28),

                        // --- Order Summary ---
                        _buildOrderSummary(shopCtrl.cartTotal),
                        const SizedBox(height: 28),



                        // --- Complete Purchase Button ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: shopCtrl.isPurchasing ? null : _completeCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: shopCtrl.isPurchasing
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.lock_outline, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pay \$${(shopCtrl.cartTotal + (shopCtrl.cartTotal * 0.08)).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            '🔒 Secured by ArtSpace — Simulated Transaction',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse the shop and add artworks you love.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.maybePop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(ArtworkModel artwork, ShopController shopCtrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.defaultRadius,
        boxShadow: AppTheme.premiumShadow,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              artwork.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: const Color(0xFFEFECE6),
                child: Icon(Icons.image_outlined, color: AppTheme.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${artwork.artistName.isNotEmpty ? artwork.artistName : "Unknown Artist"}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  artwork.priceLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              shopCtrl.removeFromCart(artwork);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(double subtotal) {
    final double tax = subtotal * 0.08;
    final double total = subtotal + tax;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: AppTheme.defaultRadius,
        boxShadow: AppTheme.premiumShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Order Summary'),
          const SizedBox(height: 14),
          _summaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow('Processing fee (8%)', '\$${tax.toStringAsFixed(2)}'),
          const Divider(height: 24, color: Color(0xFFEFECE6)),
          _summaryRow('Total', '\$${total.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              color: isBold ? AppTheme.textDark : AppTheme.textMuted,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            )),
        Text(value,
            style: TextStyle(
              color: isBold ? AppTheme.primaryAccent : AppTheme.textDark,
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            )),
      ],
    );
  }



  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.premiumShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: AppTheme.textDark, fontSize: 14),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: AppTheme.textMuted, fontSize: 13),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.surfaceWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 54),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Checkout Complete!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your artworks have been added to\nMy Collection → Purchased Art',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: AppTheme.primaryAccent,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
