import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  // Info
  InfoBox('Operation completed successfully.',
      type: InfoBoxType.info, theme: PromptTheme.dark)
    ..show();
  stdout.writeln();

  // Warning
  InfoBox.multi([
    'Low disk space on /dev/disk1s1.',
    'Consider cleaning temporary files.',
  ], type: InfoBoxType.warn, theme: PromptTheme.pastel)
    ..show();
  stdout.writeln();

  // Error
  InfoBox('Failed to connect to the database.',
      type: InfoBoxType.error, theme: PromptTheme.fire)
    ..show();
}
