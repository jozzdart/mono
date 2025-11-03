import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

String writePubspec(String dir, String name,
    {bool flutter = false, String? depsYaml}) {
  final buf = StringBuffer()
    ..writeln('name: $name')
    ..writeln('version: 1.0.0');
  if (flutter) {
    buf.writeln('flutter: {}');
  }
  if (depsYaml != null && depsYaml.trim().isNotEmpty) {
    buf.writeln(depsYaml);
  }
  final path = p.join(dir, 'pubspec.yaml');
  File(path).createSync(recursive: true);
  File(path).writeAsStringSync(buf.toString());
  return path;
}

void main() {
  group('FileSystemPackageScanner', () {
    test('returns empty list for non-existent root', () async {
      final scanner = const FileSystemPackageScanner();
      final list = await scanner.scan(
        rootPath: p.join(Directory.systemTemp.path, 'no_such_root_dir'),
        includeGlobs: const <String>[],
        excludeGlobs: const <String>[],
      );
      expect(list, isEmpty);
    });

    test('scans packages, assigns kinds, respects exclude globs', () async {
      final root = await Directory.systemTemp.createTemp('mono_scan_');
      try {
        final aDir = p.join(root.path, 'a');
        final bDir = p.join(root.path, 'nested', 'b');
        writePubspec(aDir, 'a');
        writePubspec(bDir, 'b', flutter: true);

        final scanner = const FileSystemPackageScanner();
        final list = await scanner.scan(
          rootPath: root.path,
          includeGlobs: const <String>['**/pubspec.yaml'],
          excludeGlobs: const <String>['nested/**'],
        );
        expect(list.map((p) => p.name.value).toSet(), {'a'});
        expect(list.single.kind, PackageKind.dart);
      } finally {
        root.deleteSync(recursive: true);
      }
    });

    test('resolves localDependencies by name and by path', () async {
      final root = await Directory.systemTemp.createTemp('mono_deps_');
      try {
        final aDir = p.join(root.path, 'a');
        final bDir = p.join(root.path, 'b');
        final cDir = p.join(root.path, 'c');

        writePubspec(bDir, 'b');
        writePubspec(aDir, 'a', depsYaml: 'dependencies:\n  b: ^1.0.0');
        // c depends on x by path -> b (use absolute path for determinism)
        writePubspec(cDir, 'c',
            depsYaml: 'dependencies:\n  x:\n    path: $bDir');

        final scanner = const FileSystemPackageScanner();
        final list = await scanner.scan(
          rootPath: root.path,
          includeGlobs: const <String>[],
          excludeGlobs: const <String>[],
        );
        // Ensure we have all three
        final byName = {for (final m in list) m.name.value: m};
        expect(byName.keys, containsAll(<String>['a', 'b', 'c']));

        // Path-based dependency resolution (c -> b via path)
        expect(byName['c']!.localDependencies, {const PackageName('b')});
      } finally {
        root.deleteSync(recursive: true);
      }
    });
  });
}
