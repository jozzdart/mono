import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';

import '../util/test_doubles.dart';

void main() {
  group('PubPlugin', () {
    test('supports get and clean only', () {
      final p = PubPlugin();
      expect(p.supports(const CommandId('get')), isTrue);
      expect(p.supports(const CommandId('clean')), isTrue);
      expect(p.supports(const CommandId('pub get')), isFalse);
    });

    test('runs pub get with dart for Dart package', () async {
      final p = PubPlugin();
      final runner = StubProcessRunner(returnCodes: [0]);
      final logger = RecordingLogger();
      final code = await p.execute(
        commandId: const CommandId('get'),
        package: pkg('x', path: '/repo/x', kind: PackageKind.dart),
        processRunner: runner,
        logger: logger,
      );
      expect(code, 0);
      final call = runner.calls.single;
      expect(call.command, ['dart', 'pub', 'get']);
      expect(call.cwd, '/repo/x');
    });

    test('runs pub get with flutter for Flutter package', () async {
      final p = PubPlugin();
      final runner = StubProcessRunner(returnCodes: [0]);
      final logger = RecordingLogger();
      await p.execute(
        commandId: const CommandId('get'),
        package: pkg('y', path: '/repo/y', kind: PackageKind.flutter),
        processRunner: runner,
        logger: logger,
      );
      final call = runner.calls.single;
      expect(call.command, ['flutter', 'pub', 'get']);
      expect(call.cwd, '/repo/y');
    });

    test('clean runs flutter clean for Flutter package', () async {
      final p = PubPlugin();
      final runner = StubProcessRunner(returnCodes: [0]);
      final logger = RecordingLogger();
      final code = await p.execute(
        commandId: const CommandId('clean'),
        package: pkg('f', path: '/repo/f', kind: PackageKind.flutter),
        processRunner: runner,
        logger: logger,
      );
      expect(code, 0);
      final call = runner.calls.single;
      expect(call.command, ['flutter', 'clean']);
      expect(call.cwd, '/repo/f');
    });

    test('clean is no-op for Dart package (logs and returns 0)', () async {
      final p = PubPlugin();
      final runner = StubProcessRunner(returnCodes: [999]);
      final logger = RecordingLogger();
      final code = await p.execute(
        commandId: const CommandId('clean'),
        package: pkg('d', path: '/repo/d', kind: PackageKind.dart),
        processRunner: runner,
        logger: logger,
      );
      expect(code, 0);
      expect(runner.calls, isEmpty);
      expect(
        logger.entries.map((e) => e.message),
        contains('Nothing to clean for Dart package'),
      );
    });

    test('unknown command returns 127', () async {
      final p = PubPlugin();
      final code = await p.execute(
        commandId: const CommandId('unknown'),
        package: pkg('p', path: '/repo/p'),
        processRunner: StubProcessRunner(),
        logger: RecordingLogger(),
      );
      expect(code, 127);
    });
  });
}
