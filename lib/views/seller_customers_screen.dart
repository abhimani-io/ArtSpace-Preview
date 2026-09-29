import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/seller_controller.dart';
import '../utils/app_theme.dart';

class SellerCustomersScreen extends StatelessWidget {
  const SellerCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SellerController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(ctrl),
    );
  }

  Widget _buildBody(SellerController ctrl) {
    if (ctrl.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No reviews yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: ctrl.reviews.length,
      itemBuilder: (context, index) {
        final review = ctrl.reviews[index];
        return Card(
          color: AppTheme.surfaceWhite,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppTheme.primaryAccent, child: const Icon(Icons.person, color: Colors.white)),
            title: Text(review['reviewerName'] ?? 'User', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            subtitle: Text(review['comment'] ?? '', style: TextStyle(color: AppTheme.textMuted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(' ${review['rating'] ?? 5}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}
