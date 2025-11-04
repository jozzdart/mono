import 'package:mono_cli/mono_cli.dart' hide equals;
import 'package:test/test.dart';

void main() {
  group('YamlConfigLoader', () {
    test('returns defaults for non-map YAML', () {
      final loader = YamlConfigLoader();
      final config = loader.load('42');

      expect(config.include, isEmpty);
      expect(config.exclude, isEmpty);
      expect(config.packages, isEmpty);
      expect(config.groups, isEmpty);
      expect(config.tasks, isEmpty);
      expect(config.settings.concurrency, equals('auto'));
      expect(config.settings.defaultOrder, equals('dependency'));
      expect(config.settings.shellWindows, equals('powershell'));
      expect(config.settings.shellPosix, equals('bash'));
    });

    test('parses include/exclude lists coercing values to strings', () {
      final loader = YamlConfigLoader();
      final yaml = '''
include: [packages/**, 1, true]
exclude:
  - build/**
  - 3
  - false
''';

      final config = loader.load(yaml);
      expect(config.include, equals(<String>['packages/**', '1', 'true']));
      expect(config.exclude, equals(<String>['build/**', '3', 'false']));
    });

    test('parses packages map coercing keys/values to strings', () {
      final loader = YamlConfigLoader();
      final yaml = '''
packages:
  app: apps/app
  1: 2
  other: 3
''';

      final config = loader.load(yaml);
      expect(
          config.packages,
          equals(<String, String>{
            'app': 'apps/app',
            '1': '2',
            'other': '3',
          }));
    });

    test('parses groups map to lists of strings; non-list -> empty list', () {
      final loader = YamlConfigLoader();
      final yaml = '''
groups:
  core: [app, lib/*]
  odd: single
  nums:
    - 1
    - 2
''';

      final config = loader.load(yaml);
      expect(
          config.groups,
          equals(<String, List<String>>{
            'core': ['app', 'lib/*'],
            'odd': <String>[],
            'nums': ['1', '2'],
          }));
    });

    test('parses tasks with plugin/dependsOn/env/run coercions', () {
      final loader = YamlConfigLoader();
      final yaml = '''
tasks:
  build:
    plugin: exec
    dependsOn: [clean, 1]
    env: {A: 1, B: true}
    run:
      - dart pub get
      - 42
  lint:
    plugin: analyze
  weird: 1
''';

      final config = loader.load(yaml);
      expect(config.tasks.keys, containsAll(['build', 'lint', 'weird']));

      final build = config.tasks['build']!;
      expect(build.plugin, equals('exec'));
      expect(build.dependsOn, equals(<String>['clean', '1']));
      expect(build.env, equals(<String, String>{'A': '1', 'B': 'true'}));
      expect(build.run, equals(<String>['dart pub get', '42']));

      final lint = config.tasks['lint']!;
      expect(lint.plugin, equals('analyze'));
      expect(lint.dependsOn, isEmpty);
      expect(lint.env, isEmpty);
      expect(lint.run, isEmpty);

      final weird = config.tasks['weird']!;
      expect(weird.plugin, isNull);
      expect(weird.dependsOn, isEmpty);
      expect(weird.env, isEmpty);
      expect(weird.run, isEmpty);
    });

    test('parses settings and applies defaults when absent/invalid', () {
      final loader = YamlConfigLoader();
      final yaml = '''
settings:
  concurrency: 8
  defaultOrder: none
  shellWindows: cmd
  shellPosix: zsh
''';
      final config = loader.load(yaml);
      expect(config.settings.concurrency, equals('8'));
      expect(config.settings.defaultOrder, equals('none'));
      expect(config.settings.shellWindows, equals('cmd'));
      expect(config.settings.shellPosix, equals('zsh'));

      final invalid = loader.load('settings: 3');
      expect(invalid.settings.concurrency, equals('auto'));
      expect(invalid.settings.defaultOrder, equals('dependency'));
      expect(invalid.settings.shellWindows, equals('powershell'));
      expect(invalid.settings.shellPosix, equals('bash'));
    });

    test('parses logger booleans and applies defaults when absent', () {
      final loader = YamlConfigLoader();
      final yaml = '''
logger:
  color: false
  icons: true
  timestamp: true
''';
      final config = loader.load(yaml);
      expect(config.logger.color, isFalse);
      expect(config.logger.icons, isTrue);
      expect(config.logger.timestamp, isTrue);

      final absent = loader.load('logger: {}');
      expect(absent.logger.color, isTrue);
      expect(absent.logger.icons, isTrue);
      expect(absent.logger.timestamp, isFalse);
    });
  });
}
