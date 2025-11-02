import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import 'package:path/path.dart' as p;

@immutable
class FileSystemPackageScanner implements PackageScanner {
  const FileSystemPackageScanner();

  @override
  Future<List<MonoPackage>> scan({
    required String rootPath,
    required List<String> includeGlobs,
    required List<String> excludeGlobs,
  }) async {
    final root = p.normalize(rootPath);
    final include = includeGlobs.isEmpty ? ['**/pubspec.yaml'] : includeGlobs;
    String toPubspecPattern(String pattern) {
      final t = pattern.trim();
      if (t == '**' || t == '**/' || t == '**/*' || t == '**/*/') {
        return '**/pubspec.yaml';
      }
      return t.endsWith('pubspec.yaml') ? t : p.join(t, 'pubspec.yaml');
    }

    final includeGlobsFiles = <Glob>{
      for (final pat in include) Glob(toPubspecPattern(pat), recursive: true)
    };
    final exclude = excludeGlobs.map((e) => Glob(e, recursive: true)).toList();

    final pubspecPaths = <String>{};
    final dir = Directory(root);
    if (!dir.existsSync()) return const <MonoPackage>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (p.basename(entity.path) != 'pubspec.yaml') continue;
      final rel = p.relative(entity.path, from: root);
      final matchesInclude = includeGlobsFiles.isEmpty ||
          includeGlobsFiles.any((g) => g.matches(rel));
      if (!matchesInclude) continue;
      final isExcluded =
          exclude.any((ex) => ex.matches(rel) || ex.matches(p.dirname(rel)));
      if (!isExcluded) pubspecPaths.add(entity.path);
    }

    // First pass: collect package names and paths.
    final packages = <String, MonoPackage>{};
    final rawSpecs = <String, YamlMap>{};
    for (final spec in pubspecPaths) {
      final text = await File(spec).readAsString();
      final data = loadYaml(text, recover: true);
      if (data is! YamlMap) continue;
      rawSpecs[spec] = data;
      final name = data['name']?.toString();
      if (name == null || name.isEmpty) continue;
      final pathDir = p.normalize(p.dirname(spec));
      final kind = data.nodes.containsKey('flutter')
          ? PackageKind.flutter
          : PackageKind.dart;
      packages[name] = MonoPackage(
        name: PackageName(name),
        path: p.relative(pathDir, from: root),
        kind: kind,
      );
    }

    // Second pass: resolve local path dependencies by name.
    MonoPackage withDeps(MonoPackage base, YamlMap spec) {
      final deps = <PackageName>{};
      Iterable<MapEntry> allDeps(YamlMap m) sync* {
        for (final key in ['dependencies', 'dev_dependencies']) {
          final section = m[key];
          if (section is YamlMap) {
            for (final e in section.nodes.entries) {
              yield MapEntry(e.key.value, e.value);
            }
          }
        }
      }

      for (final e in allDeps(spec)) {
        final depName = e.key.toString();
        final v = e.value;
        if (v is YamlMap && v['path'] != null) {
          // path dependency: may point to another local package dir
          final depPath = v['path'].toString();
          // try to match by name first, else by normalized path
          if (packages.containsKey(depName)) {
            deps.add(PackageName(depName));
          } else {
            final absDep = p.normalize(p.isAbsolute(depPath)
                ? depPath
                : p.join(p.dirname(p.join(root, base.path)), depPath));
            final rel = p.relative(absDep, from: root);
            final match = packages.values.firstWhere(
              (pck) => p.normalize(pck.path) == p.normalize(rel),
              orElse: () => MonoPackage(
                  name: PackageName('__none__'), path: '', kind: base.kind),
            );
            if (match.name.value != '__none__') deps.add(match.name);
          }
        } else if (packages.containsKey(depName)) {
          // direct dependency on another local package by name
          deps.add(PackageName(depName));
        }
      }

      return base.copyWith(localDependencies: deps);
    }

    final result = <MonoPackage>[];
    for (final entry in packages.entries) {
      final specPath = p.join(root, entry.value.path, 'pubspec.yaml');
      final spec = rawSpecs[specPath];
      final withLocal =
          (spec != null) ? withDeps(entry.value, spec) : entry.value;
      result.add(withLocal);
    }

    return result;
  }
}
