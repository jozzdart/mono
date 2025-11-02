import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('VersionInfo', () {
    test('StaticVersionInfo returns provided name/version', () {
      const v = StaticVersionInfo(name: 'x', version: '1.2.3');
      expect(v.name, 'x');
      expect(v.version, '1.2.3');
    });

    test('PackageVersionInfo resolves mono_cli version from pubspec', () {
      final expected = _readPackageVersion('mono_cli');
      final info = PackageVersionInfo(name: 'mono_cli');
      // Access getter (which caches internally)
      expect(info.version, expected);
    });
  });
}

String _readPackageVersion(String packageName) {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final y = loadYaml(pubspec.readAsStringSync());
      if (y is Map && y['name'] == packageName) {
        return (y['version'] ?? 'unknown').toString();
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return 'unknown';
}
