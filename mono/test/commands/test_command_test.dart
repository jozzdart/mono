import 'dart:io';

import 'package:mono/src/commands/test.dart' as cmd;
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';
import 'package:path/path.dart' as p;

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

  group('TestCommand', () {
    test('errors when no packages found', () async {
      final ws = await createTempWorkspace('mono_testcmd_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(commandPath: ['test']);
        final envBuilder = const DefaultCommandEnvironmentBuilder();

        final code = await cmd.TestCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          groupStore: groupStore,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 1);
        expect(errB.toString(),
            contains('No packages found. Run `mono scan` first.'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('dry-run plans test in dependency order', () async {
      final ws = await createTempWorkspace('mono_testcmd_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['test'],
          options: {
            'dry-run': ['1']
          },
        );
        final envBuilder = const DefaultCommandEnvironmentBuilder();

        final code = await cmd.TestCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          groupStore: groupStore,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outB.toString(),
            contains('Would run test for 1 packages in dependency order.'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
