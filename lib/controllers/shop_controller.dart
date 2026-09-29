import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/artwork_model.dart';
import '../models/purchased_art_model.dart';
import '../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// This class controls the main "Shop" screen.
// It loads all the art that sellers have uploaded and handles the shopping cart.
// ---------------------------------------------------------------------------

class ShopController extends ChangeNotifier {
  final FirestoreService _firestore;
  
  StreamSubscription? _artworksSub;
  StreamSubscription? _favoritesSub;
  StreamSubscription? _purchasesSub;

  ShopController({required FirestoreService firestore})
      : _firestore = firestore;

  // -------------------------------------------------------------------------
  // Variables that hold the shop's data
  // -------------------------------------------------------------------------
  List<ArtworkModel> _rawArtworks = [];
  List<String> _favoriteIds = [];
  List<String> get favoriteIds => _favoriteIds;
  
  List<ArtworkModel> get artworks {
    return _rawArtworks.map((a) {
      return a.copyWith(isFavorite: _favoriteIds.contains(a.id));
    }).toList();
  }

  List<PurchasedArtModel> _purchases = [];
  List<PurchasedArtModel> get purchases => _purchases;

  // -------------------------------------------------------------------------
  // Shopping Cart Data
  // -------------------------------------------------------------------------
  final List<ArtworkModel> _cart = [];
  List<ArtworkModel> get cart => List.unmodifiable(_cart);

  double get cartTotal {
    return _cart.fold(0.0, (sum, item) => sum + item.price);
  }

  bool isLoading = false;
  bool isPurchasing = false;
  String? errorMessage;

  String _selectedCategory = 'All'; // Now used as Level 1 filter (environmentCategory)
  String get selectedCategory => _selectedCategory;

  String _selectedSubcategory = 'All'; // Now used as Level 2 filter (environmentSubcategory)
  String get selectedSubcategory => _selectedSubcategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // -------------------------------------------------------------------------
  // A smart list that filters art based on what the user is searching for
  // -------------------------------------------------------------------------
  List<ArtworkModel> get filteredArtworks {
    var result = artworks;
    
    // Level 1 filter (environmentCategory)
    if (_selectedCategory != 'All') {
      result = result.where((a) => a.environmentCategory == _selectedCategory || a.category == _selectedCategory).toList();
    }
    
    // Level 2 filter (environmentSubcategory)
    if (_selectedSubcategory != 'All') {
      result = result.where((a) => a.environmentSubcategory == _selectedSubcategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((a) =>
              a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.artistName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Live database connections
  // -------------------------------------------------------------------------

  /// Connects to the database to constantly watch for new art being added to the shop.
  void startListening() {
    _artworksSub?.cancel();
    _artworksSub = _firestore.streamPublicArtworks().listen(
      (list) {
        _rawArtworks = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('ShopController artworks stream error: $e');
        errorMessage = 'Failed to load artworks.';
        notifyListeners();
      },
    );
    
    _favoritesSub?.cancel();
    _favoritesSub = _firestore.getUserFavorites().listen((favs) {
      _favoriteIds = favs;
      notifyListeners();
    });
  }

  /// Connects to the database to check what the user has already bought (to prevent them from buying it twice).
  void startListeningPurchases() {
    _purchasesSub?.cancel();
    _purchasesSub = _firestore.getUserPurchases().listen(
      (list) {
        _purchases = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('ShopController purchases stream error: $e');
      },
    );
  }

  @override
  void dispose() {
    _artworksSub?.cancel();
    _favoritesSub?.cancel();
    _purchasesSub?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Functions to sort and search the shop
  // -------------------------------------------------------------------------

  void setCategory(String category) {
    _selectedCategory = category;
    _selectedSubcategory = 'All'; // Reset subcategory when main category changes
    notifyListeners();
  }

  void setSubcategory(String subcategory) {
    _selectedSubcategory = subcategory;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Functions for buying art
  // -------------------------------------------------------------------------

  void addToCart(ArtworkModel item) {
    // Make sure we don't add the exact same painting twice
    if (!_cart.any((a) => a.id == item.id)) {
      _cart.add(item);
      notifyListeners();
    }
  }

  void removeFromCart(ArtworkModel item) {
    _cart.removeWhere((a) => a.id == item.id);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> toggleFavorite(ArtworkModel artwork) async {
    final isCurrentlyFavorite = _favoriteIds.contains(artwork.id);
    try {
      await _firestore.toggleFavorite(artwork, !isCurrentlyFavorite);
    } catch (e) {
      debugPrint('Failed to toggle favorite: $e');
    }
  }

  /// Looks at their history to see if they already own this piece of art.
  bool hasPurchased(String artworkId) {
    return _purchases.any((p) => p.artworkId == artworkId);
  }

  /// Buys everything in the cart and saves the receipts to the database.
  Future<bool> checkoutCart() async {
    if (isPurchasing || _cart.isEmpty) return false;

    isPurchasing = true;
    errorMessage = null;
    notifyListeners();

    try {
      for (final artwork in _cart) {
        await _firestore.recordPurchase(
          artworkId: artwork.id,
          title: artwork.name,
          artistName: artwork.artistName,
          artistId: artwork.artistId,
          imageUrl: artwork.imageUrl,
          price: artwork.price,
        );
      }

      _cart.clear(); // Empty the cart now that they've bought everything
      isPurchasing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Checkout error: $e');
      isPurchasing = false;
      errorMessage = 'Checkout failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
