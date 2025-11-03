import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

void main() {
  group('DefaultCommandRouter', () {
    test('dispatches registered command', () async {
      final router = DefaultCommandRouter();
      router.register('hello', ({required inv, required logger}) async {
        logger.log('hi');
        return 0;
      });
      final inv = const CliInvocation(commandPath: ['hello']);
      final code =
          await router.tryDispatch(inv: inv, logger: const StdLogger());
      expect(code, 0);
    });

    test('resolves aliases', () async {
      final router = DefaultCommandRouter();
      router.register('version', ({required inv, required logger}) async {
        return 123;
      }, aliases: const ['--version', '-v']);
      final inv = const CliInvocation(commandPath: ['-v']);
      final code =
          await router.tryDispatch(inv: inv, logger: const StdLogger());
      expect(code, 123);
    });

    test('returns null for unknown command', () async {
      final router = DefaultCommandRouter();
      final inv = const CliInvocation(commandPath: ['nope']);
      final code =
          await router.tryDispatch(inv: inv, logger: const StdLogger());
      expect(code, isNull);
    });

    test('re-registering a name overrides previous handler', () async {
      final router = DefaultCommandRouter();
      router.register('cmd', ({required inv, required logger}) async => 1);
      router.register('cmd', ({required inv, required logger}) async => 2);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['cmd']),
          logger: const StdLogger());
      expect(code, 2);
    });

    test('alias can be overridden by later registration', () async {
      final router = DefaultCommandRouter();
      router.register('a', ({required inv, required logger}) async => 10,
          aliases: const ['x']);
      router.register('b', ({required inv, required logger}) async => 20,
          aliases: const ['x']);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['x']),
          logger: const StdLogger());
      expect(code, 20);
    });

    test('empty commandPath returns null', () async {
      final router = DefaultCommandRouter();
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: []), logger: const StdLogger());
      expect(code, isNull);
    });

    test('only first token is used for dispatch (subcommands ignored)',
        () async {
      final router = DefaultCommandRouter();
      router.register('root', ({required inv, required logger}) async => 77);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['root', 'sub', 'leaf']),
          logger: const StdLogger());
      expect(code, 77);
    });

    test('case sensitivity: different case does not match', () async {
      final router = DefaultCommandRouter();
      router.register('hello', ({required inv, required logger}) async => 1);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['Hello']),
          logger: const StdLogger());
      expect(code, isNull);
    });
  });
}
