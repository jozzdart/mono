import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class FakeLoader implements ConfigLoader {
  const FakeLoader();

  @override
  MonoConfig load(String text) {
    // Very simple convention: comma-separated include globs; exclude none.
    final include = text.isEmpty ? <String>[] : text.split(',');
    return MonoConfig(include: include, exclude: const []);
  }
}

class FakeValidator implements ConfigValidator {
  const FakeValidator();

  @override
  List<ConfigIssue> validate(MonoConfig config) {
    if (config.include.isEmpty) {
      return const [ConfigIssue('include must not be empty')];
    }
    return const <ConfigIssue>[];
  }
}

class FakeSchemaProvider implements SchemaProvider {
  const FakeSchemaProvider();

  @override
  Map<String, Object?> jsonSchema() {
    return const {
      r'$schema': 'https://json-schema.org/draft/2020-12/schema',
      'type': 'object',
      'required': ['include', 'exclude'],
      'properties': {
        'include': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'exclude': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
    };
  }
}

void main() {
  group('ConfigLoader', () {
    test('loads config from text', () {
      const loader = FakeLoader();
      final cfg = loader.load('a/**,b/**');
      expect(cfg.include, equals(['a/**', 'b/**']));
      expect(cfg.exclude, isEmpty);
    });

    test('handles empty text as empty include list', () {
      const loader = FakeLoader();
      final cfg = loader.load('');
      expect(cfg.include, isEmpty);
    });
  });

  group('ConfigValidator', () {
    test('returns issue for empty include', () {
      const validator = FakeValidator();
      const cfg = MonoConfig(include: [], exclude: []);
      final issues = validator.validate(cfg);
      expect(issues, hasLength(1));
      expect(issues.first.message, contains('include'));
      expect(issues.first.severity, IssueSeverity.error);
    });

    test('returns empty list for valid include', () {
      const validator = FakeValidator();
      const cfg = MonoConfig(include: ['packages/**'], exclude: []);
      final issues = validator.validate(cfg);
      expect(issues, isEmpty);
    });
  });

  group('SchemaProvider', () {
    test('exposes a valid JSON-schema-like map', () {
      const provider = FakeSchemaProvider();
      final schema = provider.jsonSchema();
      expect(schema[r'$schema'], isA<String>());
      expect(schema['type'], equals('object'));
      expect(schema['properties'], isA<Map<String, Object?>>());
      final props = schema['properties'] as Map<String, Object?>;
      expect(props.keys, containsAll(['include', 'exclude']));
    });
  });
}
