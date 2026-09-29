import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/seller_controller.dart';
import '../utils/app_theme.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SellerController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: const Text('Orders'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(ctrl),
    );
  }

  Widget _buildBody(SellerController ctrl) {
    if (ctrl.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text('When someone purchases your art, it will appear here.', style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      itemCount: ctrl.orders.length,
      itemBuilder: (context, index) {
        final order = ctrl.orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppTheme.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(order['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,_,_)=>const Icon(Icons.image)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['title'] ?? 'Artwork', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('\$${(order['price'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(order['status'] ?? 'Pending', style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: (order['status'] == 'Pending') ? Colors.orange : AppTheme.primaryAccent,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Buyer: ${order['buyerName'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Email: ${order['buyerEmail'] ?? 'N/A'}', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                Text('Address: ${order['shippingAddress'] ?? 'N/A'}', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }
}
