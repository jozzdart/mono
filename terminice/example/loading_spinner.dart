import 'dart:io';
import 'package:terminice/terminice.dart';

void main() {
  // Example 1: Manual frame control
  print('Example 1: Manual spinner updates\n');
  final spinner = LoadingSpinner(
    'Initializing',
    message: 'Preparing workspace',
    style: SpinnerStyle.dots,
    theme: PromptTheme.pastel,
  );
  for (int i = 0; i < 20; i++) {
    spinner.show(frame: i);
    sleep(const Duration(milliseconds: 80));
  }
  spinner.clear();

  // Example 2: Using runWith callback
  print('\nExample 2: Using runWith callback\n');
  LoadingSpinner(
    'Processing',
    message: 'Compiling assets',
    style: SpinnerStyle.bars,
    theme: PromptTheme.fire,
  ).runWith((tick) {
    for (int i = 0; i < 15; i++) {
      sleep(const Duration(milliseconds: 100));
      tick();
    }
  });

  // Example 3: Simple spinner
  print('\nExample 3: Simple inline spinner\n');
  final simple = SimpleSpinner('Working...',
      style: SpinnerStyle.arcs, theme: PromptTheme.matrix);
  for (int i = 0; i < 12; i++) {
    simple.show(frame: i);
    sleep(const Duration(milliseconds: 150));
  }
  simple.clear();
  print('Done!');
}
