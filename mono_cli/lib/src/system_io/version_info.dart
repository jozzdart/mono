import 'dart:convert';
import 'dart:io';

import 'package:mono_core/mono_core.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class StaticVersionInfo implements VersionInfo {
  const StaticVersionInfo({required this.name, required this.version});

  @override
  final String name;

  @override
  final String version;
}

class PackageVersionInfo implements VersionInfo {
  PackageVersionInfo({required this.name});

  @override
  final String name;

  late final String _cachedVersion = _resolveVersionSync() ?? 'unknown';

  @override
  String get version => _cachedVersion;

  String? _resolveVersionSync() {
    try {
      final cfgPath = _findNearestPackageConfig();
      if (cfgPath == null) return null;
      final cfgDir = p.dirname(cfgPath);
      final jsonStr = File(cfgPath).readAsStringSync();
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final pkgs = (map['packages'] as List<dynamic>?) ?? const [];
      Map<String, dynamic>? entry;
      for (final e in pkgs) {
        final m = e as Map<String, dynamic>;
        if (m['name'] == name) {
          entry = m;
          break;
        }
      }
      if (entry == null) return null;
      final rootUri = entry['rootUri'] as String?; // may be relative like "../"
      if (rootUri == null) return null;
      final root = _resolveUriRelative(cfgDir, rootUri);
      final pubspecPath = p.join(root, 'pubspec.yaml');
      if (!File(pubspecPath).existsSync()) return null;
      final y = loadYaml(File(pubspecPath).readAsStringSync());
      if (y is Map && y['version'] != null) {
        return y['version'].toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _findNearestPackageConfig() {
    var dir = Directory.current;
    for (var i = 0; i < 6; i++) {
      final candidate = p.join(dir.path, '.dart_tool', 'package_config.json');
      if (File(candidate).existsSync()) return candidate;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  String _resolveUriRelative(String baseDir, String uriLike) {
    // Handles file: and relative URIs present in package_config.json
    try {
      final uri = Uri.parse(uriLike);
      if (uri.scheme == 'file') {
        return uri.toFilePath();
      }
      if (uri.scheme.isEmpty) {
        // relative to config dir
        return p.normalize(p.join(baseDir, uriLike));
      }
      // Unsupported scheme; best effort
      return uri.toFilePath();
    } catch (_) {
      return p.normalize(p.join(baseDir, uriLike));
    }
  }
}


