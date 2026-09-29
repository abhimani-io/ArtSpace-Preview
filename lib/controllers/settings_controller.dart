import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// This class manages the app's Settings screen.
// It remembers if the user prefers Light/Dark mode, their language, and notifications.
// ---------------------------------------------------------------------------

class SettingsController extends ChangeNotifier {
  final FirestoreService _firestore;

  SettingsController({required FirestoreService firestore})
      : _firestore = firestore;

  // -------------------------------------------------------------------------
  // Variables that store the user's current settings
  // -------------------------------------------------------------------------
  String _theme = 'Light';
  String _language = 'English';
  bool _notifications = true;

  String get theme => _theme;
  String get language => _language;
  bool get notifications => _notifications;

  // -------------------------------------------------------------------------
  // Live connection to the database
  // -------------------------------------------------------------------------

  /// Starts watching the database to see if the user changed settings on another device.
  void startListening() {
    _firestore.getUserSettings().listen(
      (data) {
        _theme = data['theme'] as String? ?? 'Light';
        _language = data['language'] as String? ?? 'English';
        _notifications = data['notifications'] as bool? ?? true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('SettingsController stream error: $e');
      },
    );
  }

  // -------------------------------------------------------------------------
  // Functions to change and save settings
  // -------------------------------------------------------------------------

  /// Turns notifications on or off and saves it to the database
  Future<void> setNotifications(bool value) async {
    _notifications = value; // Update the screen instantly without waiting for the database
    notifyListeners();
    await _firestore.updateSettings({'notifications': value});
  }

  /// Switches between Light Mode and Dark Mode
  Future<void> setTheme(String value) async {
    _theme = value;
    notifyListeners();
    await _firestore.updateSettings({'theme': value});
  }

  /// Changes the app's language
  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    await _firestore.updateSettings({'language': value});
  }
}
