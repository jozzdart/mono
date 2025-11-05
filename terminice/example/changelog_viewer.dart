import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  // Try reading a local CHANGELOG.md; fall back to a small demo sample.
  String? file;
  if (File('CHANGELOG.md').existsSync()) {
    file = 'CHANGELOG.md';
  } else if (File('../CHANGELOG.md').existsSync()) {
    file = '../CHANGELOG.md';
  }

  final demo = '''
# Changelog

## 1.2.0 (2025-10-01)
### Added
- New ChangeLogViewer widget with themed output.
- Optional word wrapping for long bullet lines.

### Fixed
- Minor alignment issues in borders.

## 1.1.0 - 2025-08-12
- General improvements and refactors.
- Better defaults for theme demo.
''';

  ChangeLogViewer(
    theme: PromptTheme.dark,
    filePath: file,
    content: file == null ? demo : null,
    title: 'Changelog',
    maxReleases: 8,
  ).show();
}


