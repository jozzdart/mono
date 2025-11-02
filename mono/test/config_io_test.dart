import 'dart:io';

import 'package:mono/src/config_io.dart';
import 'package:mono/src/models.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('config_io filesystem helpers', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mono_config_io_test_');
    });

    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('readFileIfExists returns empty for missing and contents for existing',
        () async {
      final missing = File('${tmp.path}/missing.txt');
      expect(await readFileIfExists(missing.path), '');

      await missing.writeAsString('hello');
      expect(await readFileIfExists(missing.path), 'hello');
    });

    test('loadRootConfig detects custom monocfgPath and defaults to monocfg',
        () async {
      final cfgPath = File('${tmp.path}/mono.yaml');
      await cfgPath.writeAsString('''
settings:
  monocfgPath: mycfg
include: ["**"]
exclude: []
groups: {}
tasks: {}
''');

      final loaded = await loadRootConfig(path: cfgPath.path);
      expect(loaded.monocfgPath, 'mycfg');

      final loadedDefault = await loadRootConfig(path: '${tmp.path}/nope.yaml');
      expect(loadedDefault.monocfgPath, 'monocfg');
    });

    test('writeRootConfigIfMissing creates once and is idempotent', () async {
      final path = '${tmp.path}/mono.yaml';
      await writeRootConfigIfMissing(path: path);
      final first = await File(path).readAsString();
      expect(first, contains('monocfgPath: monocfg'));

      // second call should not overwrite
      await File(path).writeAsString('# modified\n$first');
      await writeRootConfigIfMissing(path: path);
      final second = await File(path).readAsString();
      expect(second, startsWith('# modified'));
    });

    test('ensureMonocfgScaffold creates dir structure and is idempotent',
        () async {
      final cfgDir = '${tmp.path}/monocfg';
      await ensureMonocfgScaffold(cfgDir);

      expect(Directory(cfgDir).existsSync(), isTrue);
      expect(Directory('$cfgDir/groups').existsSync(), isTrue);
      expect(File('$cfgDir/mono_projects.yaml').existsSync(), isTrue);
      expect(File('$cfgDir/tasks.yaml').existsSync(), isTrue);

      // modify files then re-run; content should be preserved
      await File('$cfgDir/tasks.yaml').writeAsString('foo: bar\n');
      await ensureMonocfgScaffold(cfgDir);
      expect(await File('$cfgDir/tasks.yaml').readAsString(), 'foo: bar\n');
    });

    test('readMonocfgProjects handles missing/invalid and valid entries',
        () async {
      final cfgDir = '${tmp.path}/monocfg2';
      await Directory(cfgDir).create(recursive: true);

      // missing file
      expect(await readMonocfgProjects(cfgDir), isEmpty);

      // invalid YAML
      await File('$cfgDir/mono_projects.yaml').writeAsString('[]');
      expect(await readMonocfgProjects(cfgDir), isEmpty);

      // wrong shape
      await File('$cfgDir/mono_projects.yaml').writeAsString('packages: 42');
      expect(await readMonocfgProjects(cfgDir), isEmpty);

      // valid entries, with one incomplete
      await File('$cfgDir/mono_projects.yaml').writeAsString('''
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
      final list = await readMonocfgProjects(cfgDir);
      expect(list.length, 2);
      expect(list[0].name, 'a');
      expect(list[0].path, 'pkgs/a');
      expect(list[0].kind, 'dart');
      expect(list[1].name, 'b');
      expect(list[1].kind, 'flutter');
    });

    test('writeMonocfgProjects writes YAML that round-trips via reader',
        () async {
      final cfgDir = '${tmp.path}/monocfg3';
      await Directory(cfgDir).create(recursive: true);
      final pkgs = <PackageRecord>[
        const PackageRecord(name: 'x', path: 'packages/x', kind: 'dart'),
        const PackageRecord(name: 'y', path: 'packages/y', kind: 'flutter'),
      ];
      await writeMonocfgProjects(cfgDir, pkgs);
      final read = await readMonocfgProjects(cfgDir);
      expect(read.length, 2);
      expect(read.map((p) => p.name), containsAll(['x', 'y']));
      expect(read.firstWhere((p) => p.name == 'y').kind, 'flutter');
    });

    test('readMonocfgTasks parses mapping into primitives', () async {
      final cfgDir = '${tmp.path}/monocfg4';
      await Directory(cfgDir).create(recursive: true);
      await File('$cfgDir/tasks.yaml').writeAsString('''
build:
  plugin: exec
  dependsOn: [a, b]
  env:
    FOO: 1
  run:
    - echo hi
''');
      final tasks = await readMonocfgTasks(cfgDir);
      expect(tasks.keys, contains('build'));
      final b = tasks['build']!;
      expect(b['plugin'], 'exec');
      expect(b['dependsOn'], contains('a'));
      final env = b['env'] as YamlMap;
      expect(env.containsKey('FOO'), isTrue);
      expect(env['FOO'].toString(), '1');
      expect(b['run'], contains('echo hi'));
    });

    test(
        'writeRootConfigGroups preserves config and quotes special group items',
        () async {
      final cfgPath = File('${tmp.path}/mono.yaml');
      await cfgPath.writeAsString('''
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

      await writeRootConfigGroups(cfgPath.path, {
        'team': ['pkg one', 'foo:bar', 'x*y', 'hash#tag', 'quote"me'],
        'empty': <String>[],
      });

      final text = await cfgPath.readAsString();
      // preserved bits
      expect(text, contains('include:'));
      expect(text, contains('exclude:'));
      expect(text, contains('packages:'));
      expect(text, contains('tasks:'));
      // groups rendered with quotes for special items
      expect(text, contains('groups:'));
      expect(text, contains('  team:'));
      expect(text, contains('    - "pkg one"'));
      expect(text, contains('    - "foo:bar"'));
      expect(text, contains('    - "x*y"'));
      expect(text, contains('    - "hash#tag"'));
      // current implementation does not quote when only a double-quote is present
      expect(text, contains('    - quote"me'));
      // empty group printed as {}
      expect(text, contains('  empty:'));
    });
  });
}
