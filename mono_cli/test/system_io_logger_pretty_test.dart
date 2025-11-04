import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('PrettyLogger', () {
    test('does not throw on common levels and respects config toggles', () {
      final logger = PrettyLogger(const PrettyLogConfig(
        showColors: true,
        showIcons: true,
        showTimestamp: false,
      ));
      expect(() => logger.log('hello info'), returnsNormally);
      expect(() => logger.log('warn here', level: 'warn'), returnsNormally);
      expect(() => logger.log('all good', level: 'success'), returnsNormally);
      expect(() => logger.log('debug detail', level: 'debug'), returnsNormally);
      expect(() => logger.log('oops', level: 'error'), returnsNormally);

      // Toggle combinations
      final logger2 = PrettyLogger(const PrettyLogConfig(
        showColors: false,
        showIcons: false,
        showTimestamp: true,
      ));
      expect(() => logger2.log('plain'), returnsNormally);
    });
  });
}
