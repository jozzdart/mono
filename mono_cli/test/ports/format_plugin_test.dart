import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';

import '../util/test_doubles.dart';

void main() {
  group('FormatPlugin', () {
    test('supports format and format:check only', () {
      final p = FormatPlugin();
      expect(p.supports(CommandId('format')), isTrue);
      expect(p.supports(CommandId('format:check')), isTrue);
      expect(p.supports(CommandId('format:fix')), isFalse);
      expect(p.supports(CommandId('other')), isFalse);
    });

    test('runs dart format (write) with correct args', () async {
      final p = FormatPlugin();
      final runner = StubProcessRunner(returnCodes: [0]);
      final logger = RecordingLogger();
      final code = await p.execute(
        commandId: const CommandId('format'),
        package: pkg('p', path: '/r/p'),
        processRunner: runner,
        logger: logger,
      );
      expect(code, 0);
      final call = runner.calls.single;
      expect(call.command, ['dart', 'format', '.']);
      expect(call.cwd, '/r/p');
    });

    test('runs dart format --set-exit-if-changed (check)', () async {
      final p = FormatPlugin();
      final runner = StubProcessRunner(returnCodes: [1]);
      final logger = RecordingLogger();
      final code = await p.execute(
        commandId: const CommandId('format:check'),
        package: pkg('p2', path: '/root/p2'),
        processRunner: runner,
        logger: logger,
      );
      expect(code, 1);
      final call = runner.calls.single;
      expect(
        call.command,
        ['dart', 'format', '--output=none', '--set-exit-if-changed', '.'],
      );
      expect(call.cwd, '/root/p2');
    });
  });
}


