import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

import '../util/test_doubles.dart';

void main() {
  group('DefaultCommandRouter with Logger', () {
    test('forwards logger to handler', () async {
      final router = DefaultCommandRouter();
      final logger = RecordingLogger();

      router.register('log', ({required inv, required logger}) async {
        logger.log('hello', level: 'info');
        return 0;
      });

      final code = await router.tryDispatch(
        inv: const CliInvocation(commandPath: ['log']),
        logger: logger,
      );
      expect(code, 0);
      expect(logger.entries.map((e) => e.message), contains('hello'));
    });

    test('alias dispatch also forwards logger', () async {
      final router = DefaultCommandRouter();
      final logger = RecordingLogger();

      router.register('hello', ({required inv, required logger}) async {
        logger.log('alias-hit');
        return 0;
      }, aliases: const ['hi']);

      final code = await router.tryDispatch(
        inv: const CliInvocation(commandPath: ['hi']),
        logger: logger,
      );
      expect(code, 0);
      expect(logger.entries.map((e) => e.message), contains('alias-hit'));
    });
  });
}
