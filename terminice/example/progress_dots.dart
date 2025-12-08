import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  // Method 1: Using show() with manual control
  final dots = ProgressDots(
    'Loading',
    message: 'Please wait',
    theme: PromptTheme.pastel,
  );

  for (int i = 0; i < 12; i++) {
    dots.show(phase: i);
    sleep(const Duration(milliseconds: 250));
  }
  dots.clear();

  // Method 2: Using runWith callback
  ProgressDots(
    'Processing',
    message: 'Working',
    theme: PromptTheme.matrix,
  ).runWith((tick) {
    for (int i = 0; i < 10; i++) {
      tick();
      sleep(const Duration(milliseconds: 200));
    }
  });
}
