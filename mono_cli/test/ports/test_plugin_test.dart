import 'dart:io';

import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';

import '../util/test_doubles.dart';

void main() {
  group('TestPlugin', () {
    test('supports only test command', () {
      final p = TestPlugin();
      expect(p.supports(const CommandId('test')), isTrue);
      expect(p.supports(const CommandId('other')), isFalse);
    });

    test('runs dart test for Dart packages, makes cwd absolute', () async {
      final p = TestPlugin();
      final runner = StubProcessRunner(returnCodes: [0]);
      final logger = RecordingLogger();
      final relPath = 'relative_dir';
      final pkgPath = Directory.current.uri.resolve(relPath).toFilePath();
      final code = await p.execute(
        commandId: const CommandId('test'),
        package: pkg('x', path: relPath, kind: PackageKind.dart),
        processRunner: runner,
        logger: logger,
      );
      expect(code, 0);
      final call = runner.calls.single;
      expect(call.command, ['dart', 'test']);
      expect(call.cwd, pkgPath.replaceAll('/./', '/')); // normalized absolute
    });

    test('runs flutter test for Flutter packages', () async {
      final p = TestPlugin();
      final runner = StubProcessRunner(returnCodes: [0]);
      final logger = RecordingLogger();
      await p.execute(
        commandId: const CommandId('test'),
        package: pkg('y', path: '/abs/y', kind: PackageKind.flutter),
        processRunner: runner,
        logger: logger,
      );
      final call = runner.calls.single;
      expect(call.command, ['flutter', 'test']);
      expect(call.cwd, '/abs/y');
    });
  });
}
