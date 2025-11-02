import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Future<String> resolvePackageVersion(String packageName) async {
  try {
    final resolved = await Isolate.resolvePackageUri(
      Uri.parse('package:$packageName/$packageName.dart'),
    );
    if (resolved != null && resolved.scheme == 'file') {
      final libFile = resolved.toFilePath();
      final libDir = p.dirname(libFile);
      final rootDir = p.basename(libDir) == 'lib' ? p.dirname(libDir) : libDir;
      final pubspecPath = p.join(rootDir, 'pubspec.yaml');
      if (File(pubspecPath).existsSync()) {
        final y = loadYaml(File(pubspecPath).readAsStringSync());
        if (y is Map && y['version'] != null) {
          return y['version'].toString();
        }
      }
    }
  } catch (_) {
    // ignore and fall through
  }

  // Fallback: walk up from current working directory for local dev runs
  try {
    var dir = Directory.current;
    for (var i = 0; i < 6; i++) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final y = loadYaml(pubspec.readAsStringSync());
        if (y is Map && y['name'] == packageName && y['version'] != null) {
          return y['version'].toString();
        }
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  } catch (_) {
    // ignore
  }

  return 'unknown';
}
