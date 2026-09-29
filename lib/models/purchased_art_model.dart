import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// This defines what a "Purchase Receipt" is in our app.
// It stores the details of a piece of art exactly as it was when the user bought it.
// ---------------------------------------------------------------------------

class PurchasedArtModel {
  final String id;           // The unique database ID for this receipt
  final String artworkId;    // The ID of the original artwork in the shop
  final String title;        // The name of the art when they bought it
  final String artistName;   // The name of the artist
  final String imageUrl;     // The link to the high-quality picture they paid for
  final double price;        // How much money they spent
  final DateTime purchasedAt; // The exact date and time they hit 'Buy'

  const PurchasedArtModel({
    required this.id,
    required this.artworkId,
    required this.title,
    required this.artistName,
    required this.imageUrl,
    required this.price,
    required this.purchasedAt,
  });

  factory PurchasedArtModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchasedArtModel(
      id: doc.id,
      artworkId: data['artworkId'] as String? ?? '',
      title: data['title'] as String? ?? 'Untitled',
      artistName: data['artistName'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artworkId': artworkId,
      'title': title,
      'artistName': artistName,
      'imageUrl': imageUrl,
      'price': price,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
    };
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[purchasedAt.month - 1]} ${purchasedAt.day}, ${purchasedAt.year}';
  }

  String get priceLabel => '\$${price.toStringAsFixed(2)}';
}
