import 'dart:io' show Platform;

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultPlatformInfo', () {
    const info = DefaultPlatformInfo();

    test('platform booleans reflect current OS', () {
      expect(info.isWindows, Platform.isWindows);
      expect(info.isLinux, Platform.isLinux);
      expect(info.isMacOS, Platform.isMacOS);
      // Exactly one is true
      final truths = [info.isWindows, info.isLinux, info.isMacOS].where((e) => e).length;
      expect(truths, 1);
    });

    test('shell matches platform', () {
      if (Platform.isWindows) {
        expect(info.shell.toLowerCase(), contains('powershell'));
      } else {
        expect(info.shell, '/bin/bash');
      }
    });
  });
}


