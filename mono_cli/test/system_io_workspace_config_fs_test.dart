import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

void main() {
  group('FileWorkspaceConfig', () {
    late Directory tmp;
    const ws = FileWorkspaceConfig();

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mono_cli_wsconfig_');
    });

    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('loadRootConfig returns defaults for missing file', () async {
      final loaded =
          await ws.loadRootConfig(path: p.join(tmp.path, 'mono.yaml'));
      expect(loaded.monocfgPath, 'monocfg');
      expect(loaded.rawYaml, '');
      // Config loader should produce sensible defaults
      expect(loaded.config.include, isEmpty);
      expect(loaded.config.exclude, isEmpty);
    });

    test('loadRootConfig respects settings.monocfgPath', () async {
      final cfg = File(p.join(tmp.path, 'mono.yaml'));
      await cfg.create(recursive: true);
      await cfg.writeAsString('''
settings:
  monocfgPath: mycfg
include: ["**"]
exclude: []
groups: {}
tasks: {}
''');
      final loaded = await ws.loadRootConfig(path: cfg.path);
      expect(loaded.monocfgPath, 'mycfg');
      expect(loaded.rawYaml, contains('monocfgPath: mycfg'));
    });

    test('writeRootConfigIfMissing is idempotent', () async {
      final cfgPath = p.join(tmp.path, 'mono.yaml');
      await ws.writeRootConfigIfMissing(path: cfgPath);
      final first = await File(cfgPath).readAsString();
      expect(first, contains('monocfgPath: monocfg'));
      // second call should not overwrite modified content
      await File(cfgPath).writeAsString('# edited\n$first');
      await ws.writeRootConfigIfMissing(path: cfgPath);
      final second = await File(cfgPath).readAsString();
      expect(second, startsWith('# edited'));
    });

    test('ensureMonocfgScaffold creates structure and preserves existing files',
        () async {
      final cfgDir = p.join(tmp.path, 'monocfg');
      await ws.ensureMonocfgScaffold(cfgDir);

      expect(Directory(cfgDir).existsSync(), isTrue);
      expect(Directory(p.join(cfgDir, 'groups')).existsSync(), isTrue);
      expect(File(p.join(cfgDir, 'mono_projects.yaml')).existsSync(), isTrue);
      expect(File(p.join(cfgDir, 'tasks.yaml')).existsSync(), isTrue);

      // modify then re-run
      final tasksFile = File(p.join(cfgDir, 'tasks.yaml'));
      await tasksFile.writeAsString('custom: value\n');
      await ws.ensureMonocfgScaffold(cfgDir);
      expect(await tasksFile.readAsString(), 'custom: value\n');
    });

    test('readMonocfgProjects handles missing/invalid and reads valid entries',
        () async {
      final cfgDir = p.join(tmp.path, 'cfg1');
      await Directory(cfgDir).create(recursive: true);

      // missing file
      expect(await ws.readMonocfgProjects(cfgDir), isEmpty);

      // invalid YAML shape
      await File(p.join(cfgDir, 'mono_projects.yaml')).writeAsString('[]');
      expect(await ws.readMonocfgProjects(cfgDir), isEmpty);

      // wrong type for packages
      await File(p.join(cfgDir, 'mono_projects.yaml'))
          .writeAsString('packages: 42');
      expect(await ws.readMonocfgProjects(cfgDir), isEmpty);

      // valid entries (one incomplete ignored)
      await File(p.join(cfgDir, 'mono_projects.yaml')).writeAsString('''
packages:
  - name: a
    path: pkgs/a
    kind: dart
  - name: b
    path: pkgs/b
    kind: flutter
  - name: incomplete
    path: ''
''');
      final list = await ws.readMonocfgProjects(cfgDir);
      expect(list.length, 2);
      expect(list.first.name, 'a');
      expect(list.last.kind, 'flutter');
    });

    test('writeMonocfgProjects round-trips via reader', () async {
      final cfgDir = p.join(tmp.path, 'cfg2');
      await Directory(cfgDir).create(recursive: true);
      final pkgs = <PackageRecord>[
        const PackageRecord(name: 'x', path: 'packages/x', kind: 'dart'),
        const PackageRecord(name: 'y', path: 'packages/y', kind: 'flutter'),
      ];
      await ws.writeMonocfgProjects(cfgDir, pkgs);
      final read = await ws.readMonocfgProjects(cfgDir);
      expect(read.map((p) => p.name), containsAll(['x', 'y']));
    });

    test('readMonocfgTasks parses mapping into primitives', () async {
      final cfgDir = p.join(tmp.path, 'cfg3');
      await Directory(cfgDir).create(recursive: true);
      await File(p.join(cfgDir, 'tasks.yaml')).writeAsString('''
build:
  plugin: exec
  dependsOn: [a, b]
  env:
    FOO: 1
  run:
    - echo hi
''');
      final tasks = await ws.readMonocfgTasks(cfgDir);
      expect(tasks, contains('build'));
      final m = tasks['build']!;
      expect(m['plugin'], 'exec');
      expect((m['dependsOn'] as List).first, 'a');
      expect((m['env'] as Map)['FOO'].toString(), '1');
      expect((m['run'] as List).first, contains('echo'));
    });

    test('writeRootConfigGroups preserves and quotes as needed', () async {
      final cfg = File(p.join(tmp.path, 'mono.yaml'));
      await cfg.writeAsString('''
# header
settings:
  monocfgPath: monocfg
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - ".dart_tool/**"
packages:
  a: packages/a
tasks:
  t1:
    plugin: exec
    run:
      - echo 1
groups: {}
''');

      await ws.writeRootConfigGroups(cfg.path, {
        'team': ['pkg one', 'foo:bar', 'x*y', 'hash#tag', 'quote"me'],
        'empty': <String>[]
      });

      final text = await cfg.readAsString();
      expect(text, contains('groups:'));
      expect(text, contains('  team:'));
      expect(text, contains('    - "pkg one"'));
      expect(text, contains('    - "foo:bar"'));
      expect(text, contains('    - "x*y"'));
      expect(text, contains('    - "hash#tag"'));
      expect(text, contains('  empty:'));
      // preserved bits
      expect(text, contains('include:'));
      expect(text, contains('exclude:'));
      expect(text, contains('packages:'));
      expect(text, contains('tasks:'));
    });
  });
}
