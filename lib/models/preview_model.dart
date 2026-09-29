import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// This defines what a saved "Preview" is in our app.
// A preview is a photo of the user's wall with a piece of art placed on it.
// ---------------------------------------------------------------------------

class PreviewModel {
  final String id;                  // The unique database ID for this preview
  final String name;                // The name the user gave it (e.g., "Living Room")
  final String? wallImageUrl;       // The link to the photo of the blank wall
  final String? artworkImageUrl;    // The link to the artwork that was used
  final String? compositeImageUrl;  // The link to the final merged photo (wall + art together)
  final String? artworkId;          // The ID of the art used (so the user can click "Buy" later)
  final String? artworkNetworkUrl;  // Backup link to the artwork just in case
  final double scale;               // How big or small the user made the art
  final double rotation;            // How much the user tilted the art
  final double opacity;             // How see-through the art is
  final double positionLeft;        // Left/Right position on the wall
  final double positionTop;         // Up/Down position on the wall
  final DateTime createdAt;         // When this preview was saved

  const PreviewModel({
    required this.id,
    required this.name,
    this.wallImageUrl,
    this.artworkImageUrl,
    this.compositeImageUrl,
    this.artworkId,
    this.artworkNetworkUrl,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.positionLeft,
    required this.positionTop,
    required this.createdAt,
  });

  // Decides which picture to show in the list (the final merged photo is best)
  String? get thumbnailUrl {
    if (compositeImageUrl != null && compositeImageUrl!.isNotEmpty && compositeImageUrl != artworkImageUrl) {
      return compositeImageUrl;
    }
    return wallImageUrl;
  }

  // Checks if this preview uses real art from the shop, so we know if we can show a "Buy" button
  bool get hasPurchasableArtwork => artworkId != null && artworkId!.isNotEmpty;

  factory PreviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final position = data['position'] as Map<String, dynamic>? ?? {};

    return PreviewModel(
      id: doc.id,
      name: data['name'] as String? ?? 'My Preview',
      wallImageUrl: data['wallImageUrl'] as String?,
      artworkImageUrl: data['artworkImageUrl'] as String?,
      compositeImageUrl: data['compositeImageUrl'] as String?,
      artworkId: data['artworkId'] as String?,
      artworkNetworkUrl: data['artworkNetworkUrl'] as String?,
      scale: (data['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (data['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (data['opacity'] as num?)?.toDouble() ?? 1.0,
      positionLeft: (position['left'] as num?)?.toDouble() ?? 0.0,
      positionTop: (position['top'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Turns this object into raw data so we can save it to the database
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'wallImageUrl': wallImageUrl,
      'artworkImageUrl': artworkImageUrl,
      'compositeImageUrl': compositeImageUrl,
      'artworkId': artworkId,
      'artworkNetworkUrl': artworkNetworkUrl,
      'scale': scale,
      'rotation': rotation,
      'opacity': opacity,
      'position': {
        'left': positionLeft,
        'top': positionTop,
      },
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Makes the date look pretty (e.g., "Oct 12, 2023")
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }
}
