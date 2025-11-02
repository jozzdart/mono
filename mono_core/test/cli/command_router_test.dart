import 'dart:io';

import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

// A simple fake router to validate the CommandRouter contract.
class _FakeCommandRouter implements CommandRouter {
  _FakeCommandRouter();

  final Map<String, CommandHandler> _handlers = <String, CommandHandler>{};

  @override
  void register(String name, CommandHandler handler,
      {List<String> aliases = const []}) {
    _handlers[name] = handler;
    for (final alias in aliases) {
      _handlers[alias] = handler;
    }
  }

  @override
  Future<int?> tryDispatch({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
  }) async {
    if (inv.commandPath.isEmpty) return null;
    final h = _handlers[inv.commandPath.first];
    if (h == null) return null;
    return h(inv: inv, out: out, err: err);
  }
}

void main() {
  group('CommandRouter contract', () {
    test('CommandHandler typedef is callable with named parameters', () async {
      handler({
        required CliInvocation inv,
        required IOSink out,
        required IOSink err,
      }) async {
        return 42;
      }

      final inv = const CliInvocation(commandPath: ['x']);
      final code = await handler(inv: inv, out: stdout, err: stderr);
      expect(code, 42);
    });

    test('register and dispatch by name', () async {
      final router = _FakeCommandRouter();
      CliInvocation? seenInv;
      router.register('hello', (
          {required inv, required out, required err}) async {
        seenInv = inv;
        return 0;
      });
      final inv = const CliInvocation(commandPath: ['hello']);
      final code = await router.tryDispatch(inv: inv, out: stdout, err: stderr);
      expect(code, 0);
      expect(seenInv, same(inv));
    });

    test('register with aliases and dispatch via alias', () async {
      final router = _FakeCommandRouter();
      router.register('version', (
          {required inv, required out, required err}) async {
        return 7;
      }, aliases: const ['--version', '-v']);

      final code1 = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['--version']),
          out: stdout,
          err: stderr);
      final code2 = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['-v']),
          out: stdout,
          err: stderr);
      expect(code1, 7);
      expect(code2, 7);
    });

    test('returns null for unknown or empty command', () async {
      final router = _FakeCommandRouter();
      expect(
        await router.tryDispatch(
            inv: const CliInvocation(commandPath: ['nope']),
            out: stdout,
            err: stderr),
        isNull,
      );
      expect(
        await router.tryDispatch(
            inv: const CliInvocation(commandPath: []),
            out: stdout,
            err: stderr),
        isNull,
      );
    });

    test('re-registering a name overrides previous handler', () async {
      final router = _FakeCommandRouter();
      router.register(
          'cmd', ({required inv, required out, required err}) async => 1);
      router.register(
          'cmd', ({required inv, required out, required err}) async => 2);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['cmd']),
          out: stdout,
          err: stderr);
      expect(code, 2);
    });

    test('aliases can be re-bound by later registrations', () async {
      final router = _FakeCommandRouter();
      router.register(
          'a', ({required inv, required out, required err}) async => 10,
          aliases: const ['x']);
      router.register(
          'b', ({required inv, required out, required err}) async => 20,
          aliases: const ['x']);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['x']),
          out: stdout,
          err: stderr);
      expect(code, 20);
    });
  });
}
