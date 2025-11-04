import 'package:mono/src/commands/version.dart';

import 'package:test/test.dart';

import '../util/fakes.dart';

void main() {
  group('VersionCommand', () {
    test('prints name and version', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final code = await VersionCommand.runCommand(
        logger: BufferingLogger(outB, errB),
        packageName: 'mono',
        versionResolver: (packageName) => Future.value('1.2.3'),
      );
      expect(code, 0);
      expect(outB.toString().trim(), 'mono 1.2.3');
      expect(errB.toString().trim(), isEmpty);
    });
  });
}
