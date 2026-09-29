import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/seller_controller.dart';
import '../utils/app_theme.dart';

class PayoutsScreen extends StatelessWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SellerController>();
    final availableBalance = ctrl.totalRevenue; // For now, all revenue is available

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: const Text('Payouts'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.textDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.premiumShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Withdrawal initiated! (Mocked)'),
                            backgroundColor: AppTheme.primaryAccent,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Withdraw Funds', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            // Mock transaction history
            if (ctrl.orders.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text('No transactions yet.', style: TextStyle(color: AppTheme.textMuted)),
                ),
              )
            else
              ...ctrl.orders.take(5).map((order) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppTheme.surfaceWhite,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: Colors.green, size: 20),
                    ),
                    title: Text('Sale: ${order['title'] ?? 'Artwork'}', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    subtitle: Text('Status: ${order['status'] ?? 'Completed'}', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    trailing: Text(
                      '+\$${(order['price'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green, fontSize: 16),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
