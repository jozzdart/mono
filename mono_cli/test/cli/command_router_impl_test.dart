import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultCommandRouter', () {
    test('dispatches registered command', () async {
      final router = DefaultCommandRouter();
      router.register('hello', (
          {required inv, required out, required err}) async {
        out.writeln('hi');
        return 0;
      });
      final inv = const CliInvocation(commandPath: ['hello']);
      final code = await router.tryDispatch(inv: inv, out: stdout, err: stderr);
      expect(code, 0);
    });

    test('resolves aliases', () async {
      final router = DefaultCommandRouter();
      router.register('version', (
          {required inv, required out, required err}) async {
        return 123;
      }, aliases: const ['--version', '-v']);
      final inv = const CliInvocation(commandPath: ['-v']);
      final code = await router.tryDispatch(inv: inv, out: stdout, err: stderr);
      expect(code, 123);
    });

    test('returns null for unknown command', () async {
      final router = DefaultCommandRouter();
      final inv = const CliInvocation(commandPath: ['nope']);
      final code = await router.tryDispatch(inv: inv, out: stdout, err: stderr);
      expect(code, isNull);
    });

    test('re-registering a name overrides previous handler', () async {
      final router = DefaultCommandRouter();
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

    test('alias can be overridden by later registration', () async {
      final router = DefaultCommandRouter();
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

    test('empty commandPath returns null', () async {
      final router = DefaultCommandRouter();
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: []), out: stdout, err: stderr);
      expect(code, isNull);
    });

    test('only first token is used for dispatch (subcommands ignored)',
        () async {
      final router = DefaultCommandRouter();
      router.register(
          'root', ({required inv, required out, required err}) async => 77);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['root', 'sub', 'leaf']),
          out: stdout,
          err: stderr);
      expect(code, 77);
    });

    test('case sensitivity: different case does not match', () async {
      final router = DefaultCommandRouter();
      router.register(
          'hello', ({required inv, required out, required err}) async => 1);
      final code = await router.tryDispatch(
          inv: const CliInvocation(commandPath: ['Hello']),
          out: stdout,
          err: stderr);
      expect(code, isNull);
    });
  });
}
