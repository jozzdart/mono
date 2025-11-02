import 'dart:io';

import 'package:mono/src/commands/task.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../util/fs_fixtures.dart';

GroupStore _defaultGroupStoreFactory(String monocfgPath) {
  final groupsPath = const DefaultPathService().join([monocfgPath, 'groups']);
  final folder = FileListConfigFolder(
    basePath: groupsPath,
    namePolicy: const DefaultSlugNamePolicy(),
  );
  return FileGroupStore(folder);
}

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

  group('TaskCommand.tryRun', () {
    test('returns null when task is undefined', () async {
      final ws = await createTempWorkspace('mono_task_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['build']);
        final code = await TaskCommand.tryRun(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, isNull);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['build']);
        final code = await TaskCommand.tryRun(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 2);
        expect(
            errCap.text, contains('External tasks require explicit targets'));
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = CliInvocation(
          commandPath: const ['build'],
          options: const {
            'dry-run': ['1']
          },
          targets: const [TargetAll()],
        );
        final code = await TaskCommand.tryRun(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outCap.text,
            contains('Would run build for 1 packages in dependency order.'));
        expect(errCap.text.trim(), isEmpty);
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final invGet = const CliInvocation(
          commandPath: ['get'],
          options: {
            'dry-run': ['1']
          },
        );
        final codeGet = await TaskCommand.tryRun(
          inv: invGet,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(codeGet, 0);
        expect(outCap.text, contains('Would run get for 1 packages'));

        final outCap2 = CapturedIo();
        final errCap2 = CapturedIo();
        final invClean = const CliInvocation(
          commandPath: ['clean'],
          options: {
            'dry-run': ['1']
          },
        );
        final codeClean = await TaskCommand.tryRun(
          inv: invClean,
          out: outCap2.sink,
          err: errCap2.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(codeClean, 0);
        expect(outCap2.text, contains('Would run clean for 1 packages'));
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['upgrade'],
          options: {
            'dry-run': ['1']
          },
        );
        final code = await TaskCommand.tryRun(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 1);
        expect(errCap.text, contains('Unsupported pub task: upgrade'));
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['fmt'],
          options: {
            'dry-run': ['1'],
            'check': ['1']
          },
        );
        final code = await TaskCommand.tryRun(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outCap.text, contains('Would run fmt for 1 packages'));
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['foo'],
          options: {
            'dry-run': ['1']
          },
        );
        final code = await TaskCommand.tryRun(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['noop'],
          options: {
            'dry-run': ['1']
          },
          targets: [TargetAll()],
        );
        final code = await TaskCommand.tryRun(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: _defaultGroupStoreFactory,
          plugins: PluginRegistry({}),
          workspaceConfig: workspaceConfig,
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
