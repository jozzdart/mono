import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('resolvePackageVersion returns version for mono_cli', () async {
    final expected = _readPackageVersion('mono_cli');
    final v = await VersionResolver().resolvePackageVersion('mono_cli');
    expect(v, expected);
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
