import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

GroupStore groupStore = FileGroupStore(
  FileListConfigFolder(basePath: 'monocfg/groups'),
);

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
          groupStore: groupStore,
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
          const CliInvocation(commandPath: [
            'x'
          ], options: {
            'order': ['none']
          }),
          groupStore: groupStore,
        );
        expect(env.effectiveOrder, isFalse);
      } finally {
        Directory.current = prev;
        await ws.delete(recursive: true);
      }
    });
  });
}
