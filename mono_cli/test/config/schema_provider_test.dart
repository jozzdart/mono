import 'package:mono_cli/mono_cli.dart' hide equals;
import 'package:test/test.dart';

void main() {
  group('YamlSchemaProvider', () {
    test('provides top-level metadata and object type', () {
      final provider = YamlSchemaProvider();
      final schema = provider.jsonSchema();

      expect(schema[r'$schema'], isA<String>());
      expect(schema['title'], equals('mono.yaml'));
      expect(schema['type'], equals('object'));
      expect(schema['properties'], isA<Map>());
    });

    test('includes expected top-level properties', () {
      final schema = YamlSchemaProvider().jsonSchema();
      final props = schema['properties'] as Map;

      expect(
          props.keys,
          containsAll(<String>[
            'include',
            'exclude',
            'packages',
            'groups',
            'tasks',
            'settings',
          ]));
    });

    test('validates include/exclude arrays of strings', () {
      final props = YamlSchemaProvider().jsonSchema()['properties'] as Map;
      final include = props['include'] as Map;
      final exclude = props['exclude'] as Map;

      expect(include['type'], equals('array'));
      expect((include['items'] as Map)['type'], equals('string'));
      expect(exclude['type'], equals('array'));
      expect((exclude['items'] as Map)['type'], equals('string'));
    });

    test('validates packages map of strings', () {
      final props = YamlSchemaProvider().jsonSchema()['properties'] as Map;
      final packages = props['packages'] as Map;

      expect(packages['type'], equals('object'));
      expect(
          (packages['additionalProperties'] as Map)['type'], equals('string'));
    });

    test('validates groups map to array of strings', () {
      final props = YamlSchemaProvider().jsonSchema()['properties'] as Map;
      final groups = props['groups'] as Map;
      final additional = groups['additionalProperties'] as Map;

      expect(groups['type'], equals('object'));
      expect(additional['type'], equals('array'));
      expect((additional['items'] as Map)['type'], equals('string'));
    });

    test('validates tasks object shape', () {
      final props = YamlSchemaProvider().jsonSchema()['properties'] as Map;
      final tasks = props['tasks'] as Map;
      final taskDef = tasks['additionalProperties'] as Map;
      final taskProps = taskDef['properties'] as Map;

      expect(tasks['type'], equals('object'));
      expect(taskDef['type'], equals('object'));
      expect(taskProps.keys,
          containsAll(<String>['plugin', 'dependsOn', 'env', 'run']));
      expect((taskProps['plugin'] as Map)['type'], equals('string'));
      expect((taskProps['dependsOn'] as Map)['type'], equals('array'));
      expect(((taskProps['dependsOn'] as Map)['items'] as Map)['type'],
          equals('string'));
      expect((taskProps['env'] as Map)['type'], equals('object'));
      expect(((taskProps['env'] as Map)['additionalProperties'] as Map)['type'],
          equals('string'));
      expect((taskProps['run'] as Map)['type'], equals('array'));
      expect(((taskProps['run'] as Map)['items'] as Map)['type'],
          equals('string'));
    });

    test('validates settings properties and constraints', () {
      final props = YamlSchemaProvider().jsonSchema()['properties'] as Map;
      final settings = props['settings'] as Map;
      final setProps = settings['properties'] as Map;

      expect(settings['type'], equals('object'));

      final concurrencyType = setProps['concurrency'] as Map;
      expect(
          concurrencyType['type'], containsAll(<String>['string', 'integer']));

      final defaultOrder = setProps['defaultOrder'] as Map;
      expect(defaultOrder['enum'], containsAll(<String>['dependency', 'none']));

      expect((setProps['shellWindows'] as Map)['type'], equals('string'));
      expect((setProps['shellPosix'] as Map)['type'], equals('string'));
    });
  });
}
