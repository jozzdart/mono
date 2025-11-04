import 'dart:io';

import 'package:mono/src/commands/task.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';
import 'package:path/path.dart' as p;

import '../util/fs_fixtures.dart';
import '../util/fakes.dart';

GroupStore groupStore = FileGroupStore(
  FileListConfigFolder(basePath: 'monocfg/groups'),
);

Future<int> fallbackCommand() => Future.value(0);

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

  group('TaskCommand.runCommand', () {
    test('exec task without targets errors', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'build': {
            'plugin': 'exec',
            'run': ['echo hello']
          },
        });
        await ensureMonocfg('monocfg');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(commandPath: ['build']);
        final code = await TaskCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
        );
        expect(code, 2);
        expect(errB.toString(),
            contains('External tasks require explicit targets'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('exec task with targets and dry-run plans', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'build': {
            'plugin': 'exec',
            'run': ['echo hi']
          },
        });
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = CliInvocation(
          commandPath: const ['build'],
          options: const {
            'dry-run': ['1']
          },
          targets: const [TargetAll()],
        );
        final code = await TaskCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
        );
        expect(code, 0);
        expect(outB.toString(),
            contains('Would run build for 1 packages in dependency order.'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('pub get and clean map correctly', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'get': {'plugin': 'pub'},
          'clean': {'plugin': 'pub'},
        });
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final invGet = const CliInvocation(
          commandPath: ['get'],
          options: {
            'dry-run': ['1']
          },
        );
        final codeGet = await TaskCommand.runCommand(
          invocation: invGet,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
        );
        expect(codeGet, 0);
        expect(outB.toString(), contains('Would run get for 1 packages'));

        final outB2 = StringBuffer();
        final errB2 = StringBuffer();
        final invClean = const CliInvocation(
          commandPath: ['clean'],
          options: {
            'dry-run': ['1']
          },
        );
        final codeClean = await TaskCommand.runCommand(
          invocation: invClean,
          logger: BufferingLogger(outB2, errB2),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(codeClean, 0);
        expect(outB2.toString(), contains('Would run clean for 1 packages'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('unknown pub task errors', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'upgrade': {'plugin': 'pub'},
        });
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['upgrade'],
          options: {
            'dry-run': ['1']
          },
        );
        final code = await TaskCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 1);
        expect(errB.toString(), contains('Unsupported pub task: upgrade'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('format plugin with --check plans successfully', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'fmt': {'plugin': 'format'},
        });
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['fmt'],
          options: {
            'dry-run': ['1'],
            'check': ['1']
          },
        );
        final code = await TaskCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outB.toString(), contains('Would run fmt for 1 packages'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('unknown plugin yields error code', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'foo': {'plugin': 'unknown'},
        });
        writePubspec(Directory.current.path, 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['foo'],
          options: {
            'dry-run': ['1']
          },
        );
        final code = await TaskCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 1);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('exec task missing run yields error code', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'noop': {'plugin': 'exec', 'run': []},
        });
        writePubspec(Directory.current.path, 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['noop'],
          options: {
            'dry-run': ['1']
          },
          targets: [TargetAll()],
        );
        final code = await TaskCommand.runCommand(
          invocation: inv,
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          plugins: PluginRegistry({}),
          fallbackCommand: fallbackCommand,
          groupStore: groupStore,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 1);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
