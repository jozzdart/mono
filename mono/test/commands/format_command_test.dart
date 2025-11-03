import 'dart:io';

import 'package:mono/src/commands/format.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../util/fs_fixtures.dart';
import '../util/fakes.dart';

void main() {
  group('FormatCommand', () {
    test('errors when no packages found', () async {
      final ws = await createTempWorkspace('mono_format_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(commandPath: ['format']);
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

        final code = await FormatCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          groupStoreFactory: groupStoreFactory,
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

    test('dry-run plans format by default', () async {
      final ws = await createTempWorkspace('mono_format_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['format'],
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

        final code = await FormatCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          groupStoreFactory: groupStoreFactory,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outB.toString(),
            contains('Would run format for 1 packages in dependency order.'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('with --check plans format:check', () async {
      final ws = await createTempWorkspace('mono_format_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['format'],
          options: {
            'dry-run': ['1'],
            'check': ['1']
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

        final code = await FormatCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          groupStoreFactory: groupStoreFactory,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(
            outB.toString(),
            contains(
                'Would run format:check for 1 packages in dependency order.'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('order override none => input order', () async {
      final ws = await createTempWorkspace('mono_format_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(
          commandPath: ['format'],
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

        final code = await FormatCommand.run(
          inv: inv,
          logger: BufferingLogger(outB, errB),
          groupStoreFactory: groupStoreFactory,
          envBuilder: envBuilder,
          plugins: PluginRegistry({}),
          executor: const DefaultTaskExecutor(),
        );
        expect(code, 0);
        expect(outB.toString(), contains('in input order.'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
