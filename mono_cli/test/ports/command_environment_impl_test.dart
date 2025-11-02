import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DefaultCommandEnvironmentBuilder', () {
    test('extracts default monocfgPath when not set', () async {
      final ws = await Directory.systemTemp.createTemp('mono_cli_env_');
      final prev = Directory.current.path;
      try {
        Directory.current = ws.path;
        await File('mono.yaml').writeAsString('''
# mono configuration
settings:
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
''');

        final env = await const DefaultCommandEnvironmentBuilder().build(
          const CliInvocation(commandPath: ['x']),
          groupStoreFactory: (String monocfgPath) {
            final groupsPath = const DefaultPathService().join([monocfgPath, 'groups']);
            final folder = FileListConfigFolder(
              basePath: groupsPath,
              namePolicy: const DefaultSlugNamePolicy(),
            );
            return FileGroupStore(folder);
          },
        );

        expect(env.monocfgPath, 'monocfg');
        expect(env.packages, isEmpty);
        expect(env.groups, isEmpty);
        expect(env.effectiveOrder, isTrue);
        expect(env.effectiveConcurrency, greaterThanOrEqualTo(1));
      } finally {
        Directory.current = prev;
        await ws.delete(recursive: true);
      }
    });

    test('reads custom monocfgPath and loads groups, packages, and graph', () async {
      final ws = await Directory.systemTemp.createTemp('mono_cli_env_');
      final prev = Directory.current.path;
      try {
        Directory.current = ws.path;
        await File('mono.yaml').writeAsString('''
# mono configuration
settings:
  monocfgPath: cfgdir
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "cfgdir/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
''');

        // Packages
        final aDir = p.join(ws.path, 'a');
        final bDir = p.join(ws.path, 'b');
        await Directory(aDir).create(recursive: true);
        await Directory(bDir).create(recursive: true);
        await File(p.join(aDir, 'pubspec.yaml')).writeAsString('''
name: a
version: 1.0.0
dependencies:
  b:
    path: ../b
''');
        await File(p.join(bDir, 'pubspec.yaml')).writeAsString('''
name: b
version: 1.0.0
''');

        // Groups
        final groupsDir = p.join(ws.path, 'cfgdir', 'groups');
        await Directory(groupsDir).create(recursive: true);
        await File(p.join(groupsDir, 'core.list')).writeAsString('a\nb\n');

        final env = await const DefaultCommandEnvironmentBuilder().build(
          const CliInvocation(commandPath: ['x']),
          groupStoreFactory: (String monocfgPath) {
            final groupsPath = const DefaultPathService().join([monocfgPath, 'groups']);
            final folder = FileListConfigFolder(
              basePath: groupsPath,
              namePolicy: const DefaultSlugNamePolicy(),
            );
            return FileGroupStore(folder);
          },
        );

        expect(env.monocfgPath, 'cfgdir');
        expect(env.packages.length, 2);
        final names = env.packages.map((p) => p.name.value).toSet();
        expect(names, containsAll(<String>['a', 'b']));
        expect(env.graph.edges['a'], contains('b'));
        expect(env.groups['core'], containsAll(<String>['a', 'b']));

        // selector checks
        final targetsAll = env.selector.resolve(
          expressions: const <TargetExpr>[TargetAll()],
          packages: env.packages,
          groups: env.groups,
          graph: env.graph,
          dependencyOrder: true,
        );
        expect(targetsAll.length, 2);

        final targetsGroup = env.selector.resolve(
          expressions: const <TargetExpr>[TargetGroup('core')],
          packages: env.packages,
          groups: env.groups,
          graph: env.graph,
          dependencyOrder: true,
        );
        expect(targetsGroup.length, 2);
      } finally {
        Directory.current = prev;
        await ws.delete(recursive: true);
      }
    });

    test('effective order override none -> false', () async {
      final ws = await Directory.systemTemp.createTemp('mono_cli_env_');
      final prev = Directory.current.path;
      try {
        Directory.current = ws.path;
        await File('mono.yaml').writeAsString('''
# mono configuration
settings:
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
''');

        final env = await const DefaultCommandEnvironmentBuilder().build(
          const CliInvocation(commandPath: ['x'], options: {'order': ['none']}),
          groupStoreFactory: (String monocfgPath) {
            final groupsPath = const DefaultPathService().join([monocfgPath, 'groups']);
            final folder = FileListConfigFolder(
              basePath: groupsPath,
              namePolicy: const DefaultSlugNamePolicy(),
            );
            return FileGroupStore(folder);
          },
        );
        expect(env.effectiveOrder, isFalse);
      } finally {
        Directory.current = prev;
        await ws.delete(recursive: true);
      }
    });
  });
}


