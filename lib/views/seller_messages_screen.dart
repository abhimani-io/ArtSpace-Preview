import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/seller_controller.dart';
import '../utils/app_theme.dart';

class SellerMessagesScreen extends StatelessWidget {
  const SellerMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<SellerController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ctrl.messages.isEmpty ? _buildEmpty() : _buildList(ctrl),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          Text('Customer inquiries will appear here.', style: TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildList(SellerController ctrl) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: ctrl.messages.length,
      itemBuilder: (context, index) {
        final msg = ctrl.messages[index];
        final bool unread = msg['unread'] ?? false;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: AppTheme.primaryAccent),
                ),
                if (unread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              msg['sender'] ?? 'Unknown',
              style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600, color: AppTheme.textDark),
            ),
            subtitle: Text(
              msg['lastMessage'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread ? AppTheme.textDark : AppTheme.textMuted,
                fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            trailing: Text(
              msg['time'] ?? '',
              style: TextStyle(fontSize: 12, color: unread ? AppTheme.primaryAccent : AppTheme.textMuted, fontWeight: unread ? FontWeight.w700 : FontWeight.normal),
            ),
          ),
        );
      },
    );
  }
}
