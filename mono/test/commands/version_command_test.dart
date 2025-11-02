import 'package:mono/src/commands/version.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

import '../util/fakes.dart';

void main() {
  group('VersionCommand', () {
    test('prints name and version', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final inv = const CliInvocation(commandPath: ['version']);
      final code = await VersionCommand.run(
        inv: inv,
        logger: BufferingLogger(outB, errB),
        version: const StaticVersionInfo(name: 'mono', version: '1.2.3'),
      );
      expect(code, 0);
      expect(outB.toString().trim(), 'mono 1.2.3');
      expect(errB.toString().trim(), isEmpty);
    });
  });
}
