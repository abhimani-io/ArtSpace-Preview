import 'package:flutter/material.dart';
import 'art_hunt_screen.dart';

// ---------------------------------------------------------------------------
// SelectArtworkScreen — ArtSpace Preview
// A thin wrapper around ArtHuntScreen used when the user needs to pick an
// artwork AFTER they have already captured a wall photo with the camera.
//
// When [isFromCamera] is true, ArtHuntScreen → ArtworkDetailsScreen →
// WorkspaceScreen skips the "Select Wall Source" dialog and goes straight
// to the workspace using the already-captured wall image.
// ---------------------------------------------------------------------------

class SelectArtworkScreen extends StatelessWidget {
  /// True when the user arrived here after taking a wall photo with the camera.
  final bool isFromCamera;

  const SelectArtworkScreen({super.key, this.isFromCamera = false});

  @override
  Widget build(BuildContext context) {
    return ArtHuntScreen(isFromCamera: isFromCamera);
  }
}
