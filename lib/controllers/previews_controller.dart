import 'package:flutter/foundation.dart';
import '../models/preview_model.dart';
import '../services/firestore_service.dart';

// ---------------------------------------------------------------------------
// This class controls the "My Previews" screen.
// It remembers all the AR room previews the user has saved and shows them on screen.
// ---------------------------------------------------------------------------

class PreviewsController extends ChangeNotifier {
  final FirestoreService _firestore;

  PreviewsController({required FirestoreService firestore})
      : _firestore = firestore;

  // -------------------------------------------------------------------------
  // Variables that store the current data for the screen
  // -------------------------------------------------------------------------
  List<PreviewModel> _previews = [];
  List<PreviewModel> get previews => _previews;

  bool isDeleting = false;

  // -------------------------------------------------------------------------
  // Live connection to the database
  // -------------------------------------------------------------------------

  /// Starts watching the database for any new saved previews.
  /// This should be called as soon as the screen opens.
  void startListening() {
    _firestore.getUserPreviews().listen(
      (list) {
        _previews = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('PreviewsController stream error: $e');
      },
    );
  }

  // -------------------------------------------------------------------------
  // Deleting Previews
  // -------------------------------------------------------------------------

  /// Permanently removes a saved preview from the database.
  Future<void> deletePreview(String previewId) async {
    isDeleting = true;
    notifyListeners();

    try {
      await _firestore.deletePreview(previewId);
    } catch (e) {
      debugPrint('Delete preview error: $e');
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }
}
