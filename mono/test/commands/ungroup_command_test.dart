import 'dart:io';

import 'package:mono/src/commands/ungroup.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../util/fakes.dart';
import '../util/fs_fixtures.dart';

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

  group('UngroupCommand', () {
    test('usage error when name missing', () async {
      final ws = await createTempWorkspace('mono_ungroup_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(commandPath: ['ungroup']);
        final code = await UngroupCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          prompter: FakePrompter(),
          workspaceConfig: workspaceConfig,
        );
        expect(code, 2);
        expect(errB.toString(), contains('Usage: mono ungroup <group_name>'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('errors when group does not exist', () async {
      final ws = await createTempWorkspace('mono_ungroup_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['ungroup'], positionals: ['dev']);
        final code = await UngroupCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          prompter: FakePrompter(),
          workspaceConfig: workspaceConfig,
        );
        expect(code, 2);
        expect(errB.toString(), contains('Group "dev" does not exist.'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('confirm false aborts', () async {
      final ws = await createTempWorkspace('mono_ungroup_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        await writeFile(p.join('monocfg', 'groups', 'dev.list'), 'a\n');

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['ungroup'], positionals: ['dev']);
        final code = await UngroupCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          prompter: FakePrompter(nextConfirm: false),
          workspaceConfig: workspaceConfig,
        );
        expect(code, 1);
        expect(errB.toString(), contains('Aborted.'));
        expect(
            File(p.join('monocfg', 'groups', 'dev.list')).existsSync(), isTrue);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('confirm true removes group', () async {
      final ws = await createTempWorkspace('mono_ungroup_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        await writeFile(p.join('monocfg', 'groups', 'dev.list'), 'a\n');

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['ungroup'], positionals: ['dev']);
        final code = await UngroupCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          prompter: FakePrompter(nextConfirm: true),
          workspaceConfig: workspaceConfig,
        );
        expect(code, 0);
        expect(outB.toString(), contains('Group "dev" removed.'));
        expect(File(p.join('monocfg', 'groups', 'dev.list')).existsSync(),
            isFalse);
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
