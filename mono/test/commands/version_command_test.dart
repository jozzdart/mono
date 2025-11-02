import 'package:mono/src/commands/version.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

import '../util/fs_fixtures.dart';

void main() {
  group('VersionCommand', () {
    test('prints name and version', () async {
      final outCap = CapturedIo();
      final errCap = CapturedIo();
      final inv = const CliInvocation(commandPath: ['version']);
      final code = await VersionCommand.run(
        inv: inv,
        out: outCap.sink,
        err: errCap.sink,
        version: const StaticVersionInfo(name: 'mono', version: '1.2.3'),
      );
      expect(code, 0);
      expect(outCap.text.trim(), 'mono 1.2.3');
      expect(errCap.text.trim(), isEmpty);
    });
  });
}
