import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

import '../util/test_doubles.dart';

void main() {
  group('runCliApp', () {
    test('prints help and returns 0 for empty argv without registering',
        () async {
      final logger = RecordingLogger();
      var registerCalled = false;

      final code = await const DefaultCliEngine().run(
        const <String>[],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (_) {
          registerCalled = true;
        },
      );

      expect(code, 0);
      expect(registerCalled, isFalse);
      expect(logger.entries.map((e) => e.message), contains('HELP'));
    });

    test('prints help and returns 0 for --help', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['--help'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (_) {},
      );

      expect(code, 0);
      expect(logger.entries.map((e) => e.message), contains('HELP'));
    });

    test('does not print help if helpText is null', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['help'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: null,
        register: (_) {},
      );

      expect(code, 0);
      expect(logger.entries, isEmpty);
    });

    test('dispatches registered command and returns its code', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['hello'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (router) {
          router.register('hello', ({required inv, required logger}) async {
            logger.log('Hi');
            return 42;
          });
        },
      );

      expect(code, 42);
      expect(logger.entries.map((e) => e.message), contains('Hi'));
    });

    test('resolves aliases via router', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['-v'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (router) {
          router.register('version', ({required inv, required logger}) async {
            return 7;
          }, aliases: const <String>['--version', '-v']);
        },
      );

      expect(code, 7);
    });

    test('uses fallback when command not found', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['unknown'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (_) {},
        fallback: ({required inv, required logger}) async {
          return 5;
        },
      );

      expect(code, 5);
      expect(
        logger.entries.where((e) => e.level == 'error').map((e) => e.message),
        isNot(contains(startsWith('Unknown command:'))),
      );
    });

    test('returns error and logs when unknown and no fallback', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['nope'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (_) {},
      );

      expect(code, 1);
      final errors =
          logger.byLevel('error').map((e) => e.message).toList(growable: false);
      expect(errors.any((m) => m.startsWith('Unknown command: nope')), isTrue);
      expect(errors.any((m) => m.contains('Use `help`')), isTrue);
    });

    test('fallback can return null, then engine reports unknown', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['nope'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (_) {},
        fallback: ({required inv, required logger}) async => null,
      );

      expect(code, 1);
      final errors = logger.byLevel('error');
      expect(
          errors
              .map((e) => e.message)
              .any((m) => m.contains('Unknown command')),
          isTrue);
    });

    test('catches handler exceptions and returns 1 with error logs', () async {
      final logger = RecordingLogger();

      final code = await const DefaultCliEngine().run(
        const <String>['boom'],
        parser: const ArgsCliParser(),
        logger: logger,
        helpText: () => 'HELP',
        register: (router) {
          router.register('boom', ({required inv, required logger}) async {
            throw StateError('bad');
          });
        },
      );

      expect(code, 1);
      final errors = logger.byLevel('error').map((e) => e.message).toList();
      expect(errors.any((m) => m.startsWith('CLI failed: ')), isTrue);
      expect(
        errors.any(
          (m) =>
              m.contains('Bad state') ||
              m.contains('StateError') ||
              m.contains('bad'),
        ),
        isTrue,
      );
    });
  });
}
