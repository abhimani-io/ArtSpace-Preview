import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/artwork_model.dart';
import '../models/purchased_art_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// ---------------------------------------------------------------------------
// This class is the engine for the "Seller Dashboard".
// It handles:
//   - Putting new art up for sale
//   - Looking at or deleting current art listings
//   - Keeping track of how much money they've made
// ---------------------------------------------------------------------------

class SellerController extends ChangeNotifier {
  final FirestoreService _firestore;
  final StorageService _storage;

  SellerController({
    required FirestoreService firestore,
    required StorageService storage,
  })  : _firestore = firestore,
        _storage = storage;

  // -------------------------------------------------------------------------
  // Data that is currently loaded on the screen
  // -------------------------------------------------------------------------
  List<ArtworkModel> _myListings = [];
  List<ArtworkModel> get myListings => _myListings;

  List<PurchasedArtModel> _salesHistory = [];
  List<PurchasedArtModel> get salesHistory => _salesHistory;

  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> get orders => _orders;

  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> get reviews => _reviews;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  bool isUploading = false;
  bool isLoading = false;
  String? errorMessage;

  // -------------------------------------------------------------------------
  // Automatic math to calculate totals for the dashboard
  // -------------------------------------------------------------------------
  int get totalListings => _myListings.length;
  int get totalSales => _myListings.fold(0, (sum, a) => sum + a.salesCount);
  double get totalRevenue => _myListings.fold(
      0.0, (sum, a) => sum + (a.price * a.salesCount));

  // -------------------------------------------------------------------------
  // Live database connections
  // -------------------------------------------------------------------------

  /// Connects to the database to watch for changes in listings, orders, and reviews.
  void startListening(String sellerId) {
    isLoading = true;
    notifyListeners();

    _firestore.streamSellerArtworks(sellerId).listen(
      (list) {
        _myListings = list;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('SellerController listings stream error: $e');
        errorMessage = 'Failed to load your listings.';
        isLoading = false;
        notifyListeners();
      },
    );

    _firestore.streamSellerOrders(sellerId).listen(
      (list) {
        _orders = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('SellerController orders stream error: $e'),
    );

    _firestore.streamSellerReviews(sellerId).listen(
      (list) {
        _reviews = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('SellerController reviews stream error: $e'),
    );
  }

  // -------------------------------------------------------------------------
  // Uploading Art for Sale
  // -------------------------------------------------------------------------

  /// Takes the seller's image and details, and puts it in the public shop.
  Future<bool> uploadArtwork({
    required Uint8List imageBytes,
    required String title,
    required String category,
    required double price,
    required String description,
    required String artistName,
    required String sellerId,
    required String dimensions,
    required String materials,
    required String environmentCategory,
    required String environmentSubcategory,
  }) async {
    isUploading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Turn the picture into text (Base64) to save it directly
      final String imageUrl = base64Encode(imageBytes);

      print('Uploading to Firestore...');
      // Save all the details (price, name, etc.) so buyers can see it
      await _firestore.addPublicArtwork(
        imageUrl: imageUrl,
        title: title,
        category: category,
        price: price,
        description: description,
        artistName: artistName,
        artistId: sellerId,
        dimensions: dimensions,
        materials: materials,
        environmentCategory: environmentCategory,
        environmentSubcategory: environmentSubcategory,
      );

      print('Upload successful!');
      isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Firestore error: $e');
      debugPrint('SellerController upload error: $e');
      isUploading = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Removing Art from the Shop
  // -------------------------------------------------------------------------

  Future<void> deleteListing(String artworkId) async {
    try {
      await _firestore.deletePublicArtwork(artworkId);
    } catch (e) {
      debugPrint('SellerController delete error: $e');
      errorMessage = 'Failed to delete listing.';
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Fake data used for testing the dashboard design
  // -------------------------------------------------------------------------
  void loadMockData() {
    _orders = [
      {
        'title': 'Golden Sunrise',
        'price': 450.00,
        'status': 'Completed',
        'buyerName': 'Alice Johnson',
        'buyerEmail': 'alice@example.com',
        'shippingAddress': '123 Art Lane, NY 10001',
      },
      {
        'title': 'Ocean Whisper',
        'price': 320.00,
        'status': 'Pending',
        'buyerName': 'Bob Smith',
        'buyerEmail': 'bob.smith@example.com',
        'shippingAddress': '456 Ocean Drive, CA 90210',
      },
    ];

    _reviews = [
      {
        'reviewerName': 'Alice Johnson',
        'comment': 'Absolutely beautiful piece! It looks perfect in my living room.',
        'rating': 5,
      },
      {
        'reviewerName': 'Charlie Brown',
        'comment': 'Good quality, but shipping took a little longer than expected.',
        'rating': 4,
      },
    ];

    _messages = [
      {
        'sender': 'Diana Prince',
        'lastMessage': 'Is the "Midnight City" painting still available?',
        'time': '10:30 AM',
        'unread': true,
      },
      {
        'sender': 'Bruce Wayne',
        'lastMessage': 'Do you do custom commissions?',
        'time': 'Yesterday',
        'unread': false,
      },
    ];

    if (_myListings.isEmpty) {
      _myListings = [
        ArtworkModel(
          id: 'mock1',
          imageUrl: 'https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&q=80',
          name: 'Golden Sunrise',
          category: 'Art',
          isFavorite: false,
          uploadedAt: DateTime.now(),
          price: 450.00,
          description: 'A beautiful mock painting',
          artistName: 'Me',
          artistId: '123',
          dimensions: '24x36',
          materials: 'Oil',
          environmentCategory: 'Painting',
          environmentSubcategory: 'Oil',
          salesCount: 1,
        ),
        ArtworkModel(
          id: 'mock2',
          imageUrl: 'https://images.unsplash.com/photo-1579783900864-5132176465c4?w=800&q=80',
          name: 'Ocean Whisper',
          category: 'Art',
          isFavorite: false,
          uploadedAt: DateTime.now(),
          price: 320.00,
          description: 'Another mock painting',
          artistName: 'Me',
          artistId: '123',
          dimensions: '18x24',
          materials: 'Watercolor',
          environmentCategory: 'Painting',
          environmentSubcategory: 'Watercolor',
          salesCount: 1,
        ),
      ];
    }
    notifyListeners();
  }
}
