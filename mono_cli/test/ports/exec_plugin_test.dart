import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';

import '../util/test_doubles.dart';

void main() {
  group('ExecPlugin', () {
    test('supports only exec:* commands', () {
      final p = ExecPlugin();
      expect(p.supports(CommandId('exec:ls')), isTrue);
      expect(p.supports(CommandId('exec:')), isTrue);
      expect(p.supports(CommandId('format')), isFalse);
    });

    test('returns 0 and does not call runner when empty payload', () async {
      final p = ExecPlugin();
      final runner = StubProcessRunner(returnCodes: [999]);
      final logger = RecordingLogger();
      final code = await p.execute(
        commandId: CommandId('exec:   '),
        package: pkg('a', path: '/root/a'),
        processRunner: runner,
        logger: logger,
      );
      expect(code, 0);
      expect(runner.calls, isEmpty);
      expect(logger.entries, isEmpty);
    });

    test('executes command parts and forwards logs and env', () async {
      final p = ExecPlugin();
      final runner = StubProcessRunner(returnCodes: [5])
        ..stdoutPerCall.add(['hello'])
        ..stderrPerCall.add(['oops']);
      final logger = RecordingLogger();
      final code = await p.execute(
        commandId: CommandId('exec: echo  world'),
        package: pkg('pkgA', path: '/abs/pkgA'),
        processRunner: runner,
        logger: logger,
        env: const {'FOO': 'BAR'},
      );
      expect(code, 5);
      expect(runner.calls, hasLength(1));
      final call = runner.calls.single;
      expect(call.command, ['echo', 'world']);
      expect(call.cwd, '/abs/pkgA');
      expect(call.env, containsPair('FOO', 'BAR'));

      // stdout and stderr forwarded
      expect(logger.entries.length, 2);
      expect(logger.entries[0].message, 'hello');
      expect(logger.entries[0].scope, 'pkgA');
      expect(logger.entries[0].level, 'info');
      expect(logger.entries[1].message, 'oops');
      expect(logger.entries[1].scope, 'pkgA');
      expect(logger.entries[1].level, 'error');
    });
  });
}


