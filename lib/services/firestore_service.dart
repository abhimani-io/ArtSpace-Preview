import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/artwork_model.dart';
import '../models/preview_model.dart';
import '../models/purchased_art_model.dart';

// ---------------------------------------------------------------------------
// FirestoreService — ArtSpace Preview
// Central gateway for ALL Firestore read/write operations.
// ---------------------------------------------------------------------------

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // =========================================================================
  //  PREVIEWS — users/{uid}/saved_previews
  // =========================================================================

  /// Saves a preview configuration to the user's previews sub-collection.
  Future<void> saveWorkspacePreview({
    required String? wallImageUrl,
    required String? artworkImageUrl,
    required double scale,
    required double rotation,
    required double opacity,
    required double left,
    required double top,
    String name = 'My Preview',
    String? compositeImageUrl,
    String? artworkId,
    String? artworkNetworkUrl,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return;

      // Ensure parent document exists to prevent 'document does not exist' warnings
      await _db.collection('users').doc(uid).set({}, SetOptions(merge: true));

      await _db.collection('users').doc(uid).collection('saved_previews').add({
        'name': name,
        'wallImageUrl': wallImageUrl,
        'artworkImageUrl': artworkImageUrl,
        'compositeImageUrl': compositeImageUrl,
        'artworkId': artworkId,
        'artworkNetworkUrl': artworkNetworkUrl,
        'scale': scale,
        'rotation': rotation,
        'opacity': opacity,
        'position': {'left': left, 'top': top},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving preview to Firestore: $e');
      rethrow;
    }
  }

  /// Streams all saved previews for the current user, newest first.
  Stream<List<PreviewModel>> getUserPreviews() {
    try {
      final uid = _uid;
      if (uid == null) return Stream.value([]);

      return _db
          .collection('users')
          .doc(uid)
          .collection('saved_previews')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => PreviewModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error streaming previews: $e');
      return const Stream.empty();
    }
  }

  /// Deletes a single preview document.
  Future<void> deletePreview(String previewId) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      await _db
          .collection('users')
          .doc(uid)
          .collection('saved_previews')
          .doc(previewId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting preview: $e');
      rethrow;
    }
  }

  // =========================================================================
  //  PERSONAL ARTWORKS / COLLECTION — users/{uid}/artworks
  // =========================================================================

  Future<String?> saveArtworkToCollection({
    required String imageUrl,
    required String name,
    String category = 'Abstract',
  }) async {
    try {
      final uid = _uid;
      if (uid == null) return null;

      final docRef = await _db
          .collection('users')
          .doc(uid)
          .collection('artworks')
          .add({
        'imageUrl': imageUrl,
        'name': name,
        'category': category,
        'isFavorite': false,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving artwork to collection: $e');
      rethrow;
    }
  }

  Stream<List<ArtworkModel>> getUserCollection() {
    try {
      final uid = _uid;
      if (uid == null) return Stream.value([]);

      return _db
          .collection('users')
          .doc(uid)
          .collection('artworks')
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error streaming user collection: $e');
      return const Stream.empty();
    }
  }

  // =========================================================================
  //  FAVORITES — users/{uid}/favorites
  // =========================================================================

  Future<void> toggleFavorite(ArtworkModel artwork, bool isFavorite) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      
      final collectionRef = _db.collection('users').doc(uid).collection('favorites');
      
      if (isFavorite) {
        await collectionRef.add({
          'artworkId': artwork.id,
          'title': artwork.name,
          'imageUrl': artwork.imageUrl,
          'artistName': artwork.artistName,
          'addedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final snap = await collectionRef.where('artworkId', isEqualTo: artwork.id).get();
        for (var doc in snap.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  Stream<List<String>> getUserFavorites() {
    try {
      final uid = _uid;
      if (uid == null) return Stream.value([]);

      return _db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()['artworkId'] as String? ?? '').where((id) => id.isNotEmpty).toList());
    } catch (e) {
      debugPrint('Error streaming favorites: $e');
      return const Stream.empty();
    }
  }

  Future<void> toggleArtworkFavorite(String artworkId, bool newValue) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      await _db
          .collection('users')
          .doc(uid)
          .collection('artworks')
          .doc(artworkId)
          .update({'isFavorite': newValue});
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<void> deleteArtwork(String artworkId) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      await _db
          .collection('users')
          .doc(uid)
          .collection('artworks')
          .doc(artworkId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting artwork: $e');
      rethrow;
    }
  }

  // =========================================================================
  //  PUBLIC MARKETPLACE ARTWORKS — artworks/ (top-level collection)
  // =========================================================================

  /// Streams all publicly listed artworks from the marketplace, newest first.
  Stream<List<ArtworkModel>> streamPublicArtworks() {
    try {
      return _db
          .collection('artworks')
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ArtworkModel.fromPublicFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming public artworks: $e');
      return const Stream.empty();
    }
  }

  /// Streams artworks uploaded by a specific seller.
  Stream<List<ArtworkModel>> streamSellerArtworks(String sellerId) {
    try {
      return _db
          .collection('artworks')
          .where('artistId', isEqualTo: sellerId)
          .orderBy('uploadedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ArtworkModel.fromPublicFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming seller artworks: $e');
      return const Stream.empty();
    }
  }

  /// Adds a new artwork to the public marketplace.
  Future<String?> addPublicArtwork({
    required String imageUrl,
    required String title,
    required String category,
    required double price,
    required String description,
    required String artistName,
    required String artistId,
    required String dimensions,
    required String materials,
    required String environmentCategory,
    required String environmentSubcategory,
  }) async {
    try {
      final docRef = await _db.collection('artworks').add({
        'imageUrl': imageUrl,
        'title': title,
        'category': category,
        'price': price,
        'description': description,
        'artistName': artistName,
        'artistId': artistId,
        'dimensions': dimensions,
        'materials': materials,
        'environmentCategory': environmentCategory,
        'environmentSubcategory': environmentSubcategory,
        'isPurchasable': true,
        'salesCount': 0,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding public artwork: $e');
      rethrow;
    }
  }

  /// Deletes an artwork from the public marketplace (seller only).
  Future<void> deletePublicArtwork(String artworkId) async {
    try {
      await _db.collection('artworks').doc(artworkId).delete();
    } catch (e) {
      debugPrint('Error deleting public artwork: $e');
      rethrow;
    }
  }

  /// Fetches a single public artwork document.
  Future<ArtworkModel?> getPublicArtwork(String artworkId) async {
    try {
      final doc = await _db.collection('artworks').doc(artworkId).get();
      if (!doc.exists) return null;
      return ArtworkModel.fromPublicFirestore(doc);
    } catch (e) {
      debugPrint('Error getting public artwork: $e');
      return null;
    }
  }

  // =========================================================================
  //  ORDERS & REVIEWS (Global Collections for Seller Dashboard)
  // =========================================================================

  /// Streams incoming orders for a specific seller
  Stream<List<Map<String, dynamic>>> streamSellerOrders(String sellerId) {
    try {
      return _db
          .collection('orders')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('purchaseDate', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      debugPrint('Error streaming seller orders: $e');
      return const Stream.empty();
    }
  }

  /// Streams reviews for a specific artist/seller
  Stream<List<Map<String, dynamic>>> streamSellerReviews(String artistId) {
    try {
      return _db
          .collection('reviews')
          .where('artistId', isEqualTo: artistId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      debugPrint('Error streaming seller reviews: $e');
      return const Stream.empty();
    }
  }

  // =========================================================================
  //  PURCHASES — users/{uid}/purchases
  // =========================================================================

  /// Records a completed purchase in the user's purchases sub-collection.
  /// Also increments the salesCount on the artwork document.
  Future<void> recordPurchase({
    required String artworkId,
    required String title,
    required String artistName,
    required String artistId, // added artistId for seller dashboard
    required String imageUrl,
    required double price,
  }) async {
    try {
      final uid = _uid;
      if (uid == null) throw Exception('User must be logged in to purchase.');

      final WriteBatch batch = _db.batch();

      // 1. Write to purchases sub-collection
      final purchaseRef = _db
          .collection('users')
          .doc(uid)
          .collection('purchases')
          .doc();
      batch.set(purchaseRef, {
        'artworkId': artworkId,
        'title': title,
        'artistName': artistName,
        'imageUrl': imageUrl,
        'price': price,
        'purchasedAt': FieldValue.serverTimestamp(),
      });

      // 1.5. Write to global orders collection (for seller dashboard)
      final orderRef = _db.collection('orders').doc();
      batch.set(orderRef, {
        'orderId': orderRef.id,
        'artworkId': artworkId,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
        'sellerId': artistId,
        'buyerId': uid,
        'buyerName': _auth.currentUser?.displayName ?? 'Guest User',
        'buyerEmail': _auth.currentUser?.email ?? '',
        'shippingAddress': '123 Art Space Way, New York, NY 10001', // Mocked address
        'status': 'Pending',
        'purchaseDate': FieldValue.serverTimestamp(),
      });

      // 2. Increment salesCount on the artwork (use set with merge in case of mock items)
      final artworkRef = _db.collection('artworks').doc(artworkId);
      batch.set(artworkRef, {'salesCount': FieldValue.increment(1)}, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error recording purchase: $e');
      rethrow;
    }
  }

  /// Streams all purchases for the current user, newest first.
  Stream<List<PurchasedArtModel>> getUserPurchases() {
    try {
      final uid = _uid;
      if (uid == null) return Stream.value([]);

      return _db
          .collection('users')
          .doc(uid)
          .collection('purchases')
          .orderBy('purchasedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => PurchasedArtModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error streaming purchases: $e');
      return const Stream.empty();
    }
  }

  /// Checks if the current user has already purchased a specific artwork.
  Future<bool> hasUserPurchasedArtwork(String artworkId) async {
    try {
      final uid = _uid;
      if (uid == null) return false;

      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('purchases')
          .where('artworkId', isEqualTo: artworkId)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking purchase: $e');
      return false;
    }
  }

  // =========================================================================
  //  SETTINGS — users/{uid}/settings
  // =========================================================================

  Stream<Map<String, dynamic>> getUserSettings() {
    try {
      final uid = _uid;
      if (uid == null) return Stream.value(_defaultSettings);

      return _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('prefs')
          .snapshots()
          .map((snap) => snap.data() ?? _defaultSettings);
    } catch (e) {
      debugPrint('Error streaming settings: $e');
      return Stream.value(_defaultSettings);
    }
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      final uid = _uid;
      if (uid == null) return;
      await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('prefs')
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating settings: $e');
      rethrow;
    }
  }

  static const Map<String, dynamic> _defaultSettings = {
    'theme': 'Light',
    'language': 'English',
    'notifications': true,
  };
}
