import 'package:mono_cli/mono_cli.dart' hide equals;
import 'package:test/test.dart';

void main() {
  group('YamlConfigValidator', () {
    test('warns when both include and packages are empty', () {
      final validator = YamlConfigValidator();
      const config = MonoConfig(include: [], exclude: []);
      final issues = validator.validate(config);

      expect(issues, hasLength(1));
      expect(issues.first.message,
          'Either include globs or packages overrides should be provided');
      expect(issues.first.severity, IssueSeverity.warning);
      expect(issues.first.path, '/include');
    });

    test('no issues when include is provided', () {
      final validator = YamlConfigValidator();
      const config = MonoConfig(include: ['packages/**'], exclude: []);
      final issues = validator.validate(config);
      expect(issues, isEmpty);
    });

    test('no issues when packages overrides are provided', () {
      final validator = YamlConfigValidator();
      const config = MonoConfig(include: [], exclude: [], packages: {'a': 'x'});
      final issues = validator.validate(config);
      expect(issues, isEmpty);
    });
  });
}


