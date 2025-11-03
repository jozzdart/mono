import 'dart:io';

import 'package:mono/src/commands/list.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

import '../util/fs_fixtures.dart';
import '../util/fakes.dart';

GroupStore groupStore = FileGroupStore(
  FileListConfigFolder(basePath: 'monocfg/groups'),
);

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

  group('ListCommand', () {
    test('packages from cache', () async {
      final ws = await createTempWorkspace('mono_list_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        final projPath = p.join('monocfg', 'mono_projects.yaml');
        await writeFile(
          projPath,
          'packages:\n'
          '  - name: a\n'
          '    path: /tmp/a\n'
          '    kind: dart\n'
          '  - name: b\n'
          '    path: /tmp/b\n'
          '    kind: flutter\n',
        );

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
            commandPath: ['list'], positionals: ['packages']);
        final code = await ListCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          groupStore: groupStore,
        );
        expect(code, 0);
        final out = outB.toString();
        expect(out, contains('- a → /tmp/a (dart)'));
        expect(out, contains('- b → /tmp/b (flutter)'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('packages fallback scan when cache empty', () async {
      final ws = await createTempWorkspace('mono_list_');
      ws.enter();
      try {
        await writeMonoYaml();
        final aDir = p.join(Directory.current.path, 'a');
        final bDir = p.join(Directory.current.path, 'nested', 'b');
        writePubspec(aDir, 'a');
        writePubspec(bDir, 'b', flutter: true);

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
            commandPath: ['list'], positionals: ['packages']);
        final code = await ListCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          groupStore: groupStore,
        );
        expect(code, 0);
        final out = outB.toString();
        expect(out, contains('a → '));
        expect(out, contains('b → '));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('groups lists group members', () async {
      final ws = await createTempWorkspace('mono_list_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        final groupsDir = p.join('monocfg', 'groups');
        await writeFile(p.join(groupsDir, 'dev.list'), 'a\nb\n');
        await writeFile(p.join(groupsDir, 'prod.list'), 'c\n');

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['list'], positionals: ['groups']);
        final code = await ListCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          groupStore: groupStore,
        );
        expect(code, 0);
        final out = outB.toString();
        expect(out, contains('- dev → a, b'));
        expect(out, contains('- prod → c'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('tasks merges mono.yaml and monocfg/tasks.yaml', () async {
      final ws = await createTempWorkspace('mono_list_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'fmt': {'plugin': 'format'},
        });
        await ensureMonocfg('monocfg');
        await writeFile(
          p.join('monocfg', 'tasks.yaml'),
          'build:\n  plugin: exec\n  run: ["dart compile exe bin/main.dart"]\n',
        );

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['list'], positionals: ['tasks']);
        final code = await ListCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          groupStore: groupStore,
        );
        expect(code, 0);
        final out = outB.toString();
        expect(out, contains('- fmt (plugin: format)'));
        expect(out, contains('- build (plugin: exec)'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
