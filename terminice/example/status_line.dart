import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  final status = StatusLine(
    label: 'Build',
    theme: PromptTheme.pastel,
  );

  final steps = [
    'Resolving packages',
    'Compiling sources',
    'Linking objects',
    'Optimizing binary',
  ];

  for (int i = 0; i < steps.length; i++) {
    for (int j = 0; j < 5; j++) {
      status.show(steps[i], spinnerPhase: i * 5 + j);
      sleep(const Duration(milliseconds: 150));
    }
  }

  status.success('Build completed');
  sleep(const Duration(milliseconds: 500));

  stdout.writeln('Next steps: run tests, then publish.');
}
