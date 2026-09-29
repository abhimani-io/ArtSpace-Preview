import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a profile picture to Firebase Storage under the user's folder.
  Future<String?> uploadProfilePicture(String uid, Uint8List imageBytes) async {
    try {
      final Reference ref = _storage.ref().child('users/$uid/profile.jpg');
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Uploads a preview image to Firebase Storage under the user's folder.
  /// Returns the download URL on success.
  Future<String?> uploadPreview(Uint8List imageBytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final String fileName = 'preview_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('users/${user.uid}/previews/$fileName');

      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading preview to Firebase Storage: $e');
      return null;
    }
  }

  /// Uploads a composite preview image (wall + artwork merged) under the user's folder.
  Future<String?> uploadCompositePreview(Uint8List imageBytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final String fileName = 'composite_${DateTime.now().millisecondsSinceEpoch}.png';
      final Reference ref = _storage.ref().child('users/${user.uid}/composites/$fileName');

      final SettableMetadata metadata = SettableMetadata(contentType: 'image/png');
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading composite preview: $e');
      return null;
    }
  }

  /// Uploads a user's personal artwork image.
  Future<String?> uploadArtwork(Uint8List imageBytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final String fileName = 'art_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('users/${user.uid}/artworks/$fileName');

      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(imageBytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading artwork: $e');
      return null;
    }
  }

  /// Uploads a public artwork image for the marketplace (seller upload).
  /// Stored under artworks/ (public) not under users/.
  Future<String?> uploadPublicArtwork(Uint8List imageBytes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final String fileName = 'marketplace_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('marketplace/artworks/$fileName');

      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading public artwork: $e');
      return null;
    }
  }
}
