import 'package:mono_core/mono_core.dart';

@immutable
class YamlSchemaProvider implements SchemaProvider {
  const YamlSchemaProvider();

  @override
  Map<String, Object?> jsonSchema() {
    // Minimal, pragmatic schema to aid validation and tooling.
    return <String, Object?>{
      r'$schema': 'https://json-schema.org/draft/2020-12/schema',
      'title': 'mono.yaml',
      'type': 'object',
      'properties': <String, Object?>{
        'include': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'exclude': {
          'type': 'array',
          'items': {'type': 'string'},
        },
        'packages': {
          'type': 'object',
          'additionalProperties': {'type': 'string'},
        },
        'groups': {
          'type': 'object',
          'additionalProperties': {
            'type': 'array',
            'items': {'type': 'string'},
          },
        },
        'tasks': {
          'type': 'object',
          'additionalProperties': {
            'type': 'object',
            'properties': {
              'plugin': {'type': 'string'},
              'dependsOn': {
                'type': 'array',
                'items': {'type': 'string'},
              },
              'env': {
                'type': 'object',
                'additionalProperties': {'type': 'string'},
              },
              'run': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
          },
        },
        'settings': {
          'type': 'object',
          'properties': {
            'concurrency': {
              'type': ['string', 'integer']
            },
            'defaultOrder': {
              'enum': ['dependency', 'none']
            },
            'shellWindows': {'type': 'string'},
            'shellPosix': {'type': 'string'},
          },
        },
      },
    };
  }
}
