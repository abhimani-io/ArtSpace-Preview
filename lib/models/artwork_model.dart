import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// This defines what an "Artwork" is in our app.
// It is used in two places:
//   1. In a user's personal collection (art they uploaded themselves)
//   2. In the public shop (art that sellers uploaded for anyone to buy)
// ---------------------------------------------------------------------------

class ArtworkModel {
  final String id;              // The unique database ID for this artwork
  final String imageUrl;        // The internet link to the actual picture
  final String name;            // The title of the artwork
  final String category;        // E.g., Abstract, Modern, Nature, Minimal
  final bool isFavorite;        // True if the user clicked the heart icon
  final DateTime uploadedAt;    // The exact date and time it was uploaded

  // --- Details needed when selling in the Shop ---
  final double price;           // Cost in dollars (0 means it's free)
  final String artistName;      // The name of the person selling it
  final String artistId;        // The secret ID of the seller
  final String description;     // A paragraph describing the art
  final bool isPurchasable;     // True if anyone can buy it right now
  final int salesCount;         // How many times people have bought it
  final double rating;          // E.g., 4.5 out of 5 stars
  final int reviewCount;        // How many people left a review

  // --- Extra details used for filtering in the Shop ---
  final String dimensions;
  final String materials;
  final String environmentCategory;
  final String environmentSubcategory;

  // --- Testing/Local Picture Flag ---
  // If true, the picture isn't from the internet, it's saved directly in the app's files.
  // This is mostly used for fake/mock data during testing.
  final bool isLocalAsset;

  const ArtworkModel({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.isFavorite,
    required this.uploadedAt,
    this.price = 0.0,
    this.artistName = '',
    this.artistId = '',
    this.description = '',
    this.isPurchasable = false,
    this.salesCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.dimensions = '',
    this.materials = '',
    this.environmentCategory = 'Home',
    this.environmentSubcategory = '',
    this.isLocalAsset = false,
  });

  // Takes raw data from the database and builds an ArtworkModel object out of it
  factory ArtworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtworkModel(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      name: data['name'] as String? ?? 'Untitled',
      category: data['category'] as String? ?? 'Abstract',
      isFavorite: data['isFavorite'] as bool? ?? false,
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      artistName: data['artistName'] as String? ?? '',
      artistId: data['artistId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isPurchasable: data['isPurchasable'] as bool? ?? false,
      salesCount: data['salesCount'] as int? ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      dimensions: data['dimensions'] as String? ?? '',
      materials: data['materials'] as String? ?? '',
      environmentCategory: data['environmentCategory'] as String? ?? 'Home',
      environmentSubcategory: data['environmentSubcategory'] as String? ?? '',
    );
  }

  // Does the same thing as above, but for artwork loaded from the public Shop
  factory ArtworkModel.fromPublicFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtworkModel(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      name: data['title'] as String? ?? data['name'] as String? ?? 'Untitled',
      category: data['category'] as String? ?? 'Abstract',
      isFavorite: false, // We check favorites later in the ShopController
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      artistName: data['artistName'] as String? ?? '',
      artistId: data['artistId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      isPurchasable: true,
      salesCount: data['salesCount'] as int? ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      dimensions: data['dimensions'] as String? ?? '',
      materials: data['materials'] as String? ?? '',
      environmentCategory: data['environmentCategory'] as String? ?? 'Home',
      environmentSubcategory: data['environmentSubcategory'] as String? ?? '',
    );
  }

  // Takes this Artwork object and turns it into raw data so we can save it to the database
  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'name': name,
      'category': category,
      'isFavorite': isFavorite,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'price': price,
      'artistName': artistName,
      'artistId': artistId,
      'description': description,
      'isPurchasable': isPurchasable,
      'salesCount': salesCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'dimensions': dimensions,
      'materials': materials,
      'environmentCategory': environmentCategory,
      'environmentSubcategory': environmentSubcategory,
    };
  }

  // Turns it into raw data specifically formatted for the public Shop database
  Map<String, dynamic> toPublicFirestore() {
    return {
      'imageUrl': imageUrl,
      'title': name,
      'category': category,
      'price': price,
      'artistName': artistName,
      'artistId': artistId,
      'description': description,
      'isPurchasable': isPurchasable,
      'salesCount': salesCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'dimensions': dimensions,
      'materials': materials,
      'environmentCategory': environmentCategory,
      'environmentSubcategory': environmentSubcategory,
    };
  }

  ArtworkModel copyWith({
    String? id,
    String? imageUrl,
    String? name,
    String? category,
    bool? isFavorite,
    DateTime? uploadedAt,
    double? price,
    String? artistName,
    String? artistId,
    String? description,
    bool? isPurchasable,
    int? salesCount,
    double? rating,
    int? reviewCount,
    String? dimensions,
    String? materials,
    String? environmentCategory,
    String? environmentSubcategory,
    bool? isLocalAsset,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      price: price ?? this.price,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      description: description ?? this.description,
      isPurchasable: isPurchasable ?? this.isPurchasable,
      salesCount: salesCount ?? this.salesCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      dimensions: dimensions ?? this.dimensions,
      materials: materials ?? this.materials,
      environmentCategory: environmentCategory ?? this.environmentCategory,
      environmentSubcategory: environmentSubcategory ?? this.environmentSubcategory,
      isLocalAsset: isLocalAsset ?? this.isLocalAsset,
    );
  }

  // Calculates a nice human-readable time like "2 days ago" or "1 week ago"
  String get relativeDate {
    final now = DateTime.now();
    final diff = now.difference(uploadedAt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${(diff.inDays / 30).floor()} months ago';
  }

  // Makes sure the price looks pretty on screen, like "$450.00" or "Free"
  String get priceLabel {
    if (price <= 0) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }
}
