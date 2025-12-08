import 'dart:io';
import '../lib/src/src.dart';

void main() {
  // Example 1: Manual show/clear
  print('Example 1: Manual progress updates\n');
  final bar = ProgressBar('Downloading', width: 40, theme: PromptTheme.pastel);
  for (int i = 0; i <= 100; i += 10) {
    bar.show(current: i, total: 100, shimmerPhase: i ~/ 10);
    sleep(const Duration(milliseconds: 100));
  }
  bar.clear();

  // Example 2: Using runWith callback
  print('\nExample 2: Using runWith callback\n');
  ProgressBar('Processing', width: 40, theme: PromptTheme.matrix)
      .runWith((update) {
    for (int i = 0; i <= 50; i++) {
      sleep(const Duration(milliseconds: 30));
      update(i, 50);
    }
  });

  // Example 3: Simple progress
  print('\nExample 3: Simple inline progress\n');
  final simple = SimpleProgress('Loading', theme: PromptTheme.fire);
  for (int i = 0; i <= 100; i += 20) {
    simple.show(current: i, total: 100);
    sleep(const Duration(milliseconds: 200));
  }
  simple.clear();
  print('Done!');
}
