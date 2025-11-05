import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  Terminal.clearAndHome();

  stdout.writeln('${PromptTheme.dark.bold}ClockWidget Demo${PromptTheme.dark.reset}');

  // Show a themed analog + digital clock for ~15 seconds.
  ClockWidget(
    'ClockWidget',
    theme: PromptTheme.pastel,
    analog: true,
    digital: true,
    showSeconds: true,
    radius: 7,
    duration: const Duration(seconds: 15),
  ).run();
}


