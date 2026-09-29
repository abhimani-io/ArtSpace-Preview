import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/artwork_model.dart';
import '../models/purchased_art_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// ---------------------------------------------------------------------------
// This class controls the "My Collection" screen.
// It keeps track of the user's personal artwork and the art they have bought.
// ---------------------------------------------------------------------------

class CollectionController extends ChangeNotifier {
  final FirestoreService _firestore;
  final StorageService _storage;

  CollectionController({
    required FirestoreService firestore,
    required StorageService storage,
  })  : _firestore = firestore,
        _storage = storage;

  // -------------------------------------------------------------------------
  // Variables that store the current data for the screen
  // -------------------------------------------------------------------------
  List<ArtworkModel> _artworks = [];
  List<ArtworkModel> get artworks => _artworks;

  List<PurchasedArtModel> _purchases = [];
  List<PurchasedArtModel> get purchases => _purchases;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool isUploading = false;
  String? uploadError;

  // -------------------------------------------------------------------------
  // A smart list that only shows artwork matching the search or category
  // -------------------------------------------------------------------------
  List<ArtworkModel> get filteredArtworks {
    var result = _artworks;
    if (_selectedCategory != 'All') {
      result = result.where((a) => a.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((a) =>
              a.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Live connections to the database (Firestore)
  // -------------------------------------------------------------------------

  void startListening() {
    _firestore.getUserCollection().listen(
      (list) {
        _artworks = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('CollectionController stream error: $e'),
    );

    _firestore.getUserPurchases().listen(
      (list) {
        _purchases = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('CollectionController purchases stream error: $e'),
    );
  }

  // -------------------------------------------------------------------------
  // Functions to sort and search the collection
  // -------------------------------------------------------------------------

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Functions to Create, Read, Update, and Delete artwork
  // -------------------------------------------------------------------------

  Future<bool> addArtwork({
    required Uint8List imageBytes,
    required String name,
    String category = 'Abstract',
  }) async {
    isUploading = true;
    uploadError = null;
    notifyListeners();

    try {
      final String? imageUrl = await _storage.uploadArtwork(imageBytes);
      if (imageUrl == null) throw Exception('Image upload failed');

      await _firestore.saveArtworkToCollection(
        imageUrl: imageUrl,
        name: name,
        category: category,
      );

      isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add artwork error: $e');
      isUploading = false;
      uploadError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite(ArtworkModel artwork) async {
    try {
      await _firestore.toggleArtworkFavorite(artwork.id, !artwork.isFavorite);
    } catch (e) {
      debugPrint('Toggle favorite error: $e');
    }
  }

  Future<void> deleteArtwork(String artworkId) async {
    try {
      await _firestore.deleteArtwork(artworkId);
    } catch (e) {
      debugPrint('Delete artwork error: $e');
    }
  }
}
