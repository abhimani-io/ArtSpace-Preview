import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Service responsible for handling Firebase Authentication and 
/// User Role management via Cloud Firestore.
/// This complies with NFRs for robust error and network failure handling.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  /// Stream of [User] auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Gets the current authenticated user synchronously
  User? get currentUser => _firebaseAuth.currentUser;

  /// Logs in a user with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      rethrow; // Rethrow so the UI Controller can show a specific error snackbar
    } catch (e) {
      debugPrint('Unexpected Login Error: $e');
      throw Exception('An unexpected network or login error occurred.');
    }
  }

  /// Registers a new user with email, password, full name, and a specific role.
  /// The [role] parameter determines if they are a 'user' or 'seller' for routing.
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String role,
    required String fullName,
    Uint8List? profileImageBytes,
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        String? profileImageUrl;
        if (profileImageBytes != null) {
          profileImageUrl = await _storageService.uploadProfilePicture(user.uid, profileImageBytes);
        }

        // 2. Save the user's role and profile details in Cloud Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': fullName,       // Spec field: "name"
          'email': email,         // Spec field: "email"
          'role': role,           // Spec field: "role" — e.g. "seller"
          'isSeller': role == 'seller',
          'profileImageUrl': profileImageUrl,
          'createdAt': FieldValue.serverTimestamp(), // Spec field: "createdAt"
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      rethrow;
    } on FirebaseException catch (e) {
      // Handles network drops or permission issues during the Firestore write phase
      debugPrint('Firestore Database Error: ${e.message}');
      throw Exception('Failed to save user profile. Please check your connection.');
    } catch (e) {
      debugPrint('Unexpected Registration Error: $e');
      throw Exception('An unexpected network or registration error occurred.');
    }
  }

  /// Fetches the current user's role from Firestore.
  /// Crucial for the dynamic Splash/Login screen routing.
  Future<String?> getUserRole(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } on FirebaseException catch (e) {
      debugPrint('Firestore Error fetching role: ${e.message}');
      throw Exception('Failed to retrieve user role. Please check your connection.');
    } catch (e) {
      debugPrint('Unexpected error fetching role: $e');
      return null; // Fail gracefully, perhaps forcing them back to login
    }
  }

  /// Fetches the user's full data map from Firestore.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  /// Logs out the current user cleanly
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Logout Error: $e');
      throw Exception('Failed to log out cleanly. Please try again.');
    }
  }

  /// Centralized NFR compliance error handling for Firebase Auth Exceptions
  void _handleAuthError(FirebaseAuthException e) {
    debugPrint('Firebase Auth Exception: [${e.code}] ${e.message}');
    switch (e.code) {
      case 'user-not-found':
        throw Exception('No user found for that email.');
      case 'wrong-password':
        throw Exception('Wrong password provided.');
      case 'email-already-in-use':
        throw Exception('An account already exists for that email.');
      case 'invalid-email':
        throw Exception('The email address is invalid.');
      case 'weak-password':
        throw Exception('The password provided is too weak.');
      case 'network-request-failed':
        throw Exception('Network error. Please check your internet connection.');
      default:
        throw Exception(e.message ?? 'Authentication failed due to an unknown error.');
    }
  }
}
