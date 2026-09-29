
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

// ---------------------------------------------------------------------------
// WorkspaceController — ArtSpace Preview
// Manages all state for the Workspace/Preview Editor screen.
// ---------------------------------------------------------------------------

class WorkspaceController extends ChangeNotifier {
  final FirestoreService _firestore;
  final StorageService _storage;
  final ImagePicker _picker = ImagePicker();

  WorkspaceController({
    required FirestoreService firestore,
    required StorageService storage,
  })  : _firestore = firestore,
        _storage = storage;

  // -------------------------------------------------------------------------
  // Image state
  // -------------------------------------------------------------------------
  Uint8List? wallImageBytes;
  Uint8List? artworkImageBytes;
  bool isLiveCamera = false;

  // -------------------------------------------------------------------------
  // Selected artwork metadata (from the marketplace)
  // Persisted so WorkspaceScreen can pass artworkId when saving a preview.
  // -------------------------------------------------------------------------
  String? selectedArtworkId;         // Marketplace artwork ID
  String? selectedArtworkNetworkUrl;  // Network URL for display
  String? selectedArtworkAssetPath;   // Local asset path (e.g. assets/images/...)

  // Transform state is now managed locally in WorkspaceScreen to support Undo/Redo

  // -------------------------------------------------------------------------
  // Saving state
  // -------------------------------------------------------------------------
  bool isSaving = false;
  String? saveError;

  // -------------------------------------------------------------------------
  // Image Picking
  // -------------------------------------------------------------------------

  bool enableLiveCameraMode() {
    isLiveCamera = true;
    wallImageBytes = null;
    notifyListeners();
    return true;
  }

  Future<bool> pickWallFromGallery() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.photos.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
          return false;
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (photo == null) return false;

      wallImageBytes = await photo.readAsBytes();
      isLiveCamera = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return false;
    }
  }

  Future<bool> pickArtworkFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (photo == null) return false;

      artworkImageBytes = await photo.readAsBytes();
      // Clear marketplace artwork selection when picking a local image
      selectedArtworkId = null;
      selectedArtworkNetworkUrl = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Artwork picker error: $e');
      return false;
    }
  }

  void setArtworkBytes(Uint8List bytes) {
    artworkImageBytes = bytes;
    notifyListeners();
  }

  /// Called when the user selects a marketplace artwork.
  void setSelectedMarketplaceArtwork({
    required String artworkId,
    required String networkUrl,
  }) {
    selectedArtworkId = artworkId;
    selectedArtworkNetworkUrl = networkUrl;
    artworkImageBytes = null; // Clear local bytes
    notifyListeners();
  }

  /// Clears all artwork selection state (for starting fresh).
  void clearArtworkSelection() {
    artworkImageBytes = null;
    selectedArtworkId = null;
    selectedArtworkNetworkUrl = null;
    selectedArtworkAssetPath = null;
    notifyListeners();
  }

  /// Called when the user selects a local-asset artwork (from SelectArtworkScreen).
  void setSelectedLocalAsset(String assetPath) {
    selectedArtworkAssetPath = assetPath;
    selectedArtworkId = null;
    selectedArtworkNetworkUrl = null;
    artworkImageBytes = null;
    notifyListeners();
  }



  // -------------------------------------------------------------------------
  // Saving Preview
  // -------------------------------------------------------------------------

  Future<bool> savePreview({
    required double positionLeft,
    required double positionTop,
    required double scale,
    required double rotation,
    String name = 'My Preview',
    Uint8List? compositeBytes, // The rendered composite image
  }) async {
    isSaving = true;
    saveError = null;
    notifyListeners();

    try {
      String wallUrl = 'assets/images/bedroom1.jpg'; // fallback
      if (wallImageBytes != null) {
        wallUrl = await _storage.uploadPreview(wallImageBytes!) ?? wallUrl;
      }

      String artworkUrl = selectedArtworkNetworkUrl ?? selectedArtworkAssetPath ?? 'assets/images/placeholder_art.jpg';
      if (artworkImageBytes != null) {
        artworkUrl = await _storage.uploadArtwork(artworkImageBytes!) ?? artworkUrl;
      }

      String compositeUrl = '';
      if (compositeBytes != null) {
        compositeUrl = await _storage.uploadCompositePreview(compositeBytes) ?? '';
      }
      if (compositeUrl.isEmpty) {
        compositeUrl = wallUrl; // fallback to wall if composite upload fails
      }

      await _firestore.saveWorkspacePreview(
        wallImageUrl: wallUrl,
        artworkImageUrl: artworkUrl,
        compositeImageUrl: compositeUrl,
        artworkId: selectedArtworkId,
        artworkNetworkUrl: selectedArtworkNetworkUrl ?? artworkUrl,
        scale: scale,
        rotation: rotation,
        opacity: 1.0, // Default since opacity is removed
        left: positionLeft,
        top: positionTop,
        name: name,
      );

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('WorkspaceController save error: $e');
      isSaving = false;
      saveError = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
