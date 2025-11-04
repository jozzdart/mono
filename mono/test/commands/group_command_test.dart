import 'dart:io';

import 'package:mono/src/commands/group.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

import '../util/fakes.dart';
import '../util/fs_fixtures.dart';

GroupStore groupStore = FileGroupStore(
  FileListConfigFolder(basePath: 'monocfg/groups'),
);

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

  group('GroupCommand', () {
    test('usage error when name missing', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(commandPath: ['group']);
        final code = await GroupCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          groupStore: groupStore,
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          prompter: FakePrompter(),
          plugins: PluginRegistry({}),
        );
        expect(code, 2);
        expect(errB.toString(), contains('Usage: mono group <group_name>'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('invalid name starting with :', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: [':bad']);
        final code = await GroupCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          groupStore: groupStore,
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          prompter: FakePrompter(),
          plugins: PluginRegistry({}),
        );
        expect(code, 2);
        expect(errB.toString(), contains('Invalid group name: ":bad"'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('existing group and confirm false aborts', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        final groupsDir = p.join('monocfg', 'groups');
        await writeFile(p.join(groupsDir, 'dev.list'), 'a\n');

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['dev']);
        final code = await GroupCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          prompter: FakePrompter(nextConfirm: false),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          groupStore: groupStore,
          plugins: PluginRegistry({}),
        );
        expect(code, 1);
        expect(errB.toString(), contains('Aborted.'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('creates group with selected indices', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        // No cache -> will scan
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        writePubspec(p.join(Directory.current.path, 'b'), 'b');
        writePubspec(p.join(Directory.current.path, 'c'), 'c');

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['g1']);
        final code = await GroupCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          prompter: FakePrompter(checklistIndices: [0, 2]),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          groupStore: groupStore,
          plugins: PluginRegistry({}),
        );
        expect(code, 0);
        expect(outB.toString(), contains('Group "g1" saved with 2 member(s).'));
        final f = File(p.join('monocfg', 'groups', 'g1.list'));
        expect(f.existsSync(), isTrue);
        final lines = await f.readAsLines();
        expect(lines, containsAll(<String>['a', 'c']));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('no selections and confirm false => aborts', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['g2']);
        final code = await GroupCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          groupStore: groupStore,
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          prompter: FakePrompter(checklistIndices: [], nextConfirm: false),
          plugins: PluginRegistry({}),
        );
        expect(code, 1);
        expect(errB.toString(), contains('Aborted.'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('conflicts with package name', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'foo'), 'foo');

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['foo']);
        final code = await GroupCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          prompter: FakePrompter(),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
          groupStore: groupStore,
          plugins: PluginRegistry({}),
        );
        expect(code, 2);
        expect(errB.toString(),
            contains('Cannot create group with same name as a package'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
