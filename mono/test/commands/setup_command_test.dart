import 'dart:io';

import 'package:mono/src/commands/setup.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../util/fs_fixtures.dart';

void main() {
  group('SetupCommand', () {
    test('creates mono.yaml and scaffolds monocfg', () async {
      final ws = await createTempWorkspace('mono_setup_');
      ws.enter();
      try {
        expect(File('mono.yaml').existsSync(), isFalse);

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['setup']);
        final code = await SetupCommand.run(
            inv: inv, out: outCap.sink, err: errCap.sink);
        expect(code, 0);

        expect(File('mono.yaml').existsSync(), isTrue);
        expect(Directory(p.join('monocfg')).existsSync(), isTrue);
        expect(Directory(p.join('monocfg', 'groups')).existsSync(), isTrue);
        expect(
            File(p.join('monocfg', 'mono_projects.yaml')).existsSync(), isTrue);
        expect(File(p.join('monocfg', 'tasks.yaml')).existsSync(), isTrue);
        expect(outCap.text, contains('Created/verified mono.yaml'));
        expect(errCap.text.trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('is idempotent when files already exist', () async {
      final ws = await createTempWorkspace('mono_setup_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['setup']);
        final code = await SetupCommand.run(
            inv: inv, out: outCap.sink, err: errCap.sink);
        expect(code, 0);
        expect(File('mono.yaml').existsSync(), isTrue);
        expect(Directory(p.join('monocfg', 'groups')).existsSync(), isTrue);
        expect(
            File(p.join('monocfg', 'mono_projects.yaml')).existsSync(), isTrue);
        expect(File(p.join('monocfg', 'tasks.yaml')).existsSync(), isTrue);
        expect(errCap.text.trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
