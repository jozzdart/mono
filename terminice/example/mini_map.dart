import 'dart:io';

import '../lib/src/src.dart';

void main() {
  final total = 1000;
  final view = 48;
  final marks = [42, 128, 256, 512, 777, 900, 940];

  for (final start in [0, 120, 240, 360, 480, 600, 720, 840, 952]) {
    Terminal.clearAndHome();
    MiniMap(
      totalLines: total,
      viewportStart: start,
      viewportSize: view,
      height: 24,
      width: 18,
      label: 'Mini Map',
      theme: PromptTheme.pastel,
      markers: marks,
    ).show();
    sleep(const Duration(milliseconds: 260));
  }
}
