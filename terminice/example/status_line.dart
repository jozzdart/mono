import 'dart:io';
import 'dart:async';

import '../lib/src/src.dart';

void main() async {
  final status = StatusLine(
    label: 'Build',
    theme: PromptTheme.pastel, // aligns with ThemeDemo aesthetics
    showSpinner: true,
  );

  status.start();

  final steps = [
    'Resolving packages',
    'Compiling sources',
    'Linking objects',
    'Optimizing binary',
  ];

  for (final step in steps) {
    status.update(step);
    sleep(const Duration(milliseconds: 700));
  }

  status.success('Build completed');

  // Keep it visible a moment, then stop (leaves the final line rendered)
  await Future<void>.delayed(const Duration(milliseconds: 900));
  status.stop();

  // Print a normal line to show the rest of the app output continues above
  stdout.writeln('Next steps: run tests, then publish.');
}


