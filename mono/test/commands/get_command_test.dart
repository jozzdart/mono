import 'dart:io';

import 'package:mono/src/commands/get.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../util/fs_fixtures.dart';

void main() {
  group('GetCommand', () {
    test('errors when no packages found', () async {
      final ws = await createTempWorkspace('mono_get_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['get']);
        final envBuilder = const DefaultCommandEnvironmentBuilder();
        groupStoreFactory(String monocfgPath) {
          final groupsPath =
              const DefaultPathService().join([monocfgPath, 'groups']);
          final folder = FileListConfigFolder(
            basePath: groupsPath,
            namePolicy: const DefaultSlugNamePolicy(),
          );
          return FileGroupStore(folder);
        }

        final code = await GetCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: groupStoreFactory,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 1);
        expect(
            errCap.text, contains('No packages found. Run `mono scan` first.'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('dry-run plans get in dependency order by default', () async {
      final ws = await createTempWorkspace('mono_get_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['get'],
          options: {
            'dry-run': ['1']
          },
        );
        final envBuilder = const DefaultCommandEnvironmentBuilder();
        groupStoreFactory(String monocfgPath) {
          final groupsPath =
              const DefaultPathService().join([monocfgPath, 'groups']);
          final folder = FileListConfigFolder(
            basePath: groupsPath,
            namePolicy: const DefaultSlugNamePolicy(),
          );
          return FileGroupStore(folder);
        }

        final code = await GetCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: groupStoreFactory,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outCap.text,
            contains('Would run get for 1 packages in dependency order.'));
        expect(errCap.text.trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('order override none => input order', () async {
      final ws = await createTempWorkspace('mono_get_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['get'],
          options: {
            'dry-run': ['1'],
            'order': ['none']
          },
        );
        final envBuilder = const DefaultCommandEnvironmentBuilder();
        groupStoreFactory(String monocfgPath) {
          final groupsPath =
              const DefaultPathService().join([monocfgPath, 'groups']);
          final folder = FileListConfigFolder(
            basePath: groupsPath,
            namePolicy: const DefaultSlugNamePolicy(),
          );
          return FileGroupStore(folder);
        }

        final code = await GetCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          groupStoreFactory: groupStoreFactory,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outCap.text, contains('in input order.'));
        expect(errCap.text.trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
