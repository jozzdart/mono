import 'dart:io' show Platform;

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultProcessRunner', () {
    const runner = DefaultProcessRunner();

    test('runs a simple echo command and captures stdout', () async {
      final lines = <String>[];
      final code = await runner.run(
        Platform.isWindows
            ? <String>['cmd', '/c', 'echo', 'hello']
            : <String>['/bin/bash', '-lc', 'echo hello'],
        onStdout: lines.add,
      );
      expect(code, 0);
      expect(lines.where((l) => l.trim() == 'hello'), isNotEmpty);
    });

    test('captures stderr and non-zero exit code', () async {
      final errs = <String>[];
      final code = await runner.run(
        Platform.isWindows
            ? <String>['cmd', '/c', 'echo err 1>&2 & exit /b 3']
            : <String>['/bin/bash', '-lc', 'echo err 1>&2; exit 3'],
        onStderr: errs.add,
      );
      expect(code, isNot(0));
      expect(errs.where((l) => l.contains('err')), isNotEmpty);
    });
  });
}



