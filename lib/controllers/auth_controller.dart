import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// This class handles everything related to user accounts (login, register, logout).
/// It connects our backend services to the screens the user sees,
/// and keeps track of loading states, errors, and what type of user is logged in.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _firebaseUser;
  String? _userRole;
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _errorMessage;

  // --- Data that our screens can read ---
  User? get firebaseUser => _firebaseUser;
  String? get userRole => _userRole;
  String? get profileImageUrl => _profileImageUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// A simple way to check if someone is logged in right now
  bool get isAuthenticated => _firebaseUser != null;

  AuthController() {
    // Always listen to see if the user logs in or logs out
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        await _fetchAndSyncUserRole(user.uid);
      } else {
        _userRole = null;
        _profileImageUrl = null;
      }
      notifyListeners(); // Tell the app to update the screens with the new info
    });
  }

  // --- Helper functions used only inside this class ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Gets the user's role and profile picture from the database and saves it here
  Future<void> _fetchAndSyncUserRole(String uid) async {
    try {
      final data = await _authService.getUserData(uid);
      if (data != null) {
        _userRole = data['role'] as String?;
        _profileImageUrl = data['profileImageUrl'] as String?;
      } else {
        _userRole = await _authService.getUserRole(uid);
      }
    } catch (e) {
      debugPrint('AuthController data fetch error: $e');
      // If we can't get the data, just ignore it for now
    }
  }

  // --- Functions our screens can call ---

  /// Logs the user in. Returns true if it worked, false if it failed.
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // We don't need to do anything else here, the listener above will handle the rest!
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      // Remove the ugly "Exception: " text before showing the error to the user
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Creates a new account for the user and assigns them a role (like 'buyer' or 'seller').
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role, // Can be 'user' or 'seller'
    Uint8List? profileImageBytes,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.registerWithEmailAndPassword(
        email: email.trim(),
        password: password,
        role: role,
        fullName: fullName.trim(),
        profileImageBytes: profileImageBytes,
      );
      // Save the role right away so the app knows where to take the user next
      _userRole = role; 
      if (_firebaseUser != null) {
        await _fetchAndSyncUserRole(_firebaseUser!.uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Safely logs the user out of the app
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      _setError('Failed to logout cleanly. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Wipes away any old error messages (good to call when leaving a screen)
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Uploads a new profile picture and updates the user's account
  Future<bool> uploadAndUpdateProfileImage(Uint8List imageBytes) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return false;
    
    _setLoading(true);
    _setError(null);
    try {
      final storageService = StorageService();
      final url = await storageService.uploadProfilePicture(uid, imageBytes);
      
      if (url != null) {
        // Save the new image link in our database
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profileImageUrl': url,
        });
        
        // Update the user's main Firebase profile too
        await _firebaseUser?.updatePhotoURL(url);
        
        // Update our local variable so the screen changes immediately
        _profileImageUrl = url;
        _setLoading(false);
        return true;
      } else {
        _setError('Failed to upload image. Please try again.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      _setError('Error updating profile image: ${e.toString()}');
      return false;
    }
  }
}
