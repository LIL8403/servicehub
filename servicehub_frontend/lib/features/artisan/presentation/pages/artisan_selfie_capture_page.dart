// Reserved for a dedicated selfie capture screen.
//
// The selfie capture currently lives inside ArtisanIdDocumentPage as an
// inline photo slot. If design review decides it should be a full-screen
// experience (live camera preview, retake flow, etc.), this file will
// host that page and the ID document page will push to it.

import 'package:flutter/material.dart';

class ArtisanSelfieCapturePage extends StatelessWidget {
  const ArtisanSelfieCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}