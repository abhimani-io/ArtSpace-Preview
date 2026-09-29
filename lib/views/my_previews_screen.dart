import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/previews_controller.dart';
import '../models/preview_model.dart';
import '../utils/app_theme.dart';
import 'preview_fullscreen.dart';

// ---------------------------------------------------------------------------
// MyPreviewsScreen — ArtSpace Preview (Screen #8)
// Displays a 2-column masonry-style grid of all the user's saved previews.
// Each card shows a thumbnail, room name, and date. Tapping opens the full
// screen view. Long-pressing shows a delete option.
// ---------------------------------------------------------------------------

class MyPreviewsScreen extends StatefulWidget {
  const MyPreviewsScreen({super.key});

  @override
  State<MyPreviewsScreen> createState() => _MyPreviewsScreenState();
}

class _MyPreviewsScreenState extends State<MyPreviewsScreen> {
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
    final controller = context.watch<PreviewsController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Padding(
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
                    'My Previews',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'All your saved previews',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

            // --- Grid or Empty State ---
            Expanded(
              child: _previews.isEmpty
                  ? _buildEmptyState()
                  : _buildPreviewsGrid(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewsGrid(PreviewsController controller) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: _previews.length,
      itemBuilder: (_, index) {
        final preview = _previews[index];
        return _PreviewCard(
          preview: preview,
          onTap: () => _openFullScreen(preview),
          onDelete: () => _confirmDelete(preview.id, controller),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 60, color: AppTheme.textMuted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No previews saved yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the workspace to create your first preview',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(PreviewModel preview) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewFullScreen(
          preview: preview,
          imageUrl: preview.thumbnailUrl ?? '',
        ),
      ),
    );
  }

  void _confirmDelete(String previewId, PreviewsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              controller.deletePreview(previewId);
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
// _PreviewCard — Individual preview card in the grid
// ---------------------------------------------------------------------------
class _PreviewCard extends StatelessWidget {
  final PreviewModel preview;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PreviewCard({
    required this.preview,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: AppTheme.smallRadius,
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: preview.thumbnailUrl != null
                        ? (preview.thumbnailUrl!.startsWith('http')
                            ? Image.network(
                                preview.thumbnailUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => _placeholderImage(),
                                loadingBuilder: (_, child, progress) =>
                                    progress == null ? child : _loadingWidget(),
                              )
                            : Image.asset(
                                preview.thumbnailUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => _placeholderImage(),
                              ))
                        : _placeholderImage(),
                  ),
                  // Options menu (3-dot button)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _showOptions(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
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

            // Name + date
            Padding(
              padding: const EdgeInsets.all(10),
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
                  Text(
                    preview.formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFEFECE6),
      child: Center(
        child: Icon(Icons.image_outlined,
            size: 40, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _loadingWidget() {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppTheme.primaryAccent,
      ),
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
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              title: const Text('Delete',
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
