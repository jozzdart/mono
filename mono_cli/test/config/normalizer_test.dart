import 'package:mono_cli/mono_cli.dart' hide equals;
import 'package:test/test.dart';

void main() {
  group('normalizeRootConfig', () {
    test('generates canonical YAML and logs additions', () {
      final result = normalizeRootConfig(
        'include: ["**"]\n',
        monocfgPath: 'monocfg',
      );
      expect(result.yaml, contains('settings:'));
      expect(result.yaml, contains('logger:'));
      expect(result.yaml, contains('include:'));
      expect(result.yaml, contains('exclude:'));
      expect(result.messages.join('\n'), contains('settings'));
      expect(result.messages.join('\n'), contains('logger'));
    });
  });
}
