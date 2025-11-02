import 'dart:io';

import 'package:mono/src/commands/format.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../util/fs_fixtures.dart';

void main() {
  group('FormatCommand', () {
    test('errors when no packages found', () async {
      final ws = await createTempWorkspace('mono_format_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['format']);
        final code = await FormatCommand.run(
            inv: inv, out: outCap.sink, err: errCap.sink);
        expect(code, 1);
        expect(
            errCap.text, contains('No packages found. Run `mono scan` first.'));
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['format'],
          options: {
            'dry-run': ['1']
          },
        );
        final code = await FormatCommand.run(
            inv: inv, out: outCap.sink, err: errCap.sink);
        expect(code, 0);
        expect(outCap.text,
            contains('Would run format for 1 packages in dependency order.'));
        expect(errCap.text.trim(), isEmpty);
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['format'],
          options: {
            'dry-run': ['1'],
            'check': ['1']
          },
        );
        final code = await FormatCommand.run(
            inv: inv, out: outCap.sink, err: errCap.sink);
        expect(code, 0);
        expect(
            outCap.text,
            contains(
                'Would run format:check for 1 packages in dependency order.'));
        expect(errCap.text.trim(), isEmpty);
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
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(
          commandPath: ['format'],
          options: {
            'dry-run': ['1'],
            'order': ['none']
          },
        );
        final code = await FormatCommand.run(
            inv: inv, out: outCap.sink, err: errCap.sink);
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
