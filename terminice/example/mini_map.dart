import 'dart:io';

import '../lib/src/src.dart';

void main() {
  final total = 1000;
  final view = 48;
  final marks = [42, 128, 256, 512, 777, 900, 940];

  // Use RenderOutput for partial clearing (only clears our widget's lines)
  final out = RenderOutput();

  for (final start in [0, 120, 240, 360, 480, 600, 720, 840, 952]) {
    out.clear(); // Clear only the previous MiniMap output
    MiniMap(
      totalLines: total,
      viewportStart: start,
      viewportSize: view,
      height: 24,
      width: 18,
      label: 'Mini Map',
      theme: PromptTheme.pastel,
      markers: marks,
    ).showTo(out); // Render to our tracked output
    sleep(const Duration(milliseconds: 260));
  }
}
