import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('Settings', () {
    test('has expected defaults', () {
      const settings = Settings();
      expect(settings.concurrency, equals('auto'));
      expect(settings.defaultOrder, equals('dependency'));
      expect(settings.shellWindows, equals('powershell'));
      expect(settings.shellPosix, equals('bash'));
    });

    test('stores provided values', () {
      const settings = Settings(
        concurrency: '4',
        defaultOrder: 'none',
        shellWindows: 'cmd',
        shellPosix: 'zsh',
      );
      expect(settings.concurrency, equals('4'));
      expect(settings.defaultOrder, equals('none'));
      expect(settings.shellWindows, equals('cmd'));
      expect(settings.shellPosix, equals('zsh'));
    });

    test('const canonicalization for identical literals', () {
      const a = Settings();
      const b = Settings();
      expect(identical(a, b), isTrue);
    });
  });

  group('TaskDefinition', () {
    test('has expected defaults', () {
      const def = TaskDefinition();
      expect(def.plugin, isNull);
      expect(def.dependsOn, isEmpty);
      expect(def.env, isEmpty);
      expect(def.run, isEmpty);
    });

    test('stores provided values', () {
      const def = TaskDefinition(
        plugin: 'exec',
        dependsOn: ['a', 'b'],
        env: {'FOO': 'bar'},
        run: ['echo', 'hi'],
      );
      expect(def.plugin, equals('exec'));
      expect(def.dependsOn, equals(['a', 'b']));
      expect(def.env, equals({'FOO': 'bar'}));
      expect(def.run, equals(['echo', 'hi']));
    });

    test('const canonicalization for identical literals', () {
      const a = TaskDefinition();
      const b = TaskDefinition();
      expect(identical(a, b), isTrue);
    });
  });

  group('MonoConfig', () {
    test('applies defaults for optional fields', () {
      const cfg = MonoConfig(include: ['packages/**'], exclude: []);
      expect(cfg.include, equals(['packages/**']));
      expect(cfg.exclude, isEmpty);
      expect(cfg.dartProjects, isEmpty);
      expect(cfg.flutterProjects, isEmpty);
      expect(cfg.groups, isEmpty);
      expect(cfg.tasks, isEmpty);
      expect(cfg.settings.concurrency, equals('auto'));
    });

    test('stores provided complex values', () {
      const settings = Settings(concurrency: '8', defaultOrder: 'none');
      const task = TaskDefinition(plugin: 'exec', run: ['dart', 'fmt']);
      const cfg = MonoConfig(
        include: ['apps/**', 'packages/**'],
        exclude: ['**/build/**'],
        dartProjects: {'core': 'packages/core'},
        groups: {
          'ci': ['core', 'apps/*'],
        },
        tasks: {'fmt': task},
        settings: settings,
      );

      expect(cfg.include, equals(['apps/**', 'packages/**']));
      expect(cfg.exclude, equals(['**/build/**']));
      expect(cfg.dartProjects, equals({'core': 'packages/core'}));
      expect(
          cfg.groups,
          equals({
            'ci': ['core', 'apps/*']
          }));
      expect(cfg.tasks.keys, contains('fmt'));
      expect(cfg.tasks['fmt']?.plugin, equals('exec'));
      expect(cfg.settings.concurrency, equals('8'));
      expect(cfg.settings.defaultOrder, equals('none'));
    });
  });

  group('ConfigIssue', () {
    test('defaults to error severity and null path', () {
      const issue = ConfigIssue('boom');
      expect(issue.message, equals('boom'));
      expect(issue.severity, equals(IssueSeverity.error));
      expect(issue.path, isNull);
    });

    test('stores provided severity and path', () {
      const issue = ConfigIssue(
        'warn',
        severity: IssueSeverity.warning,
        path: '/tasks/0',
      );
      expect(issue.message, equals('warn'));
      expect(issue.severity, equals(IssueSeverity.warning));
      expect(issue.path, equals('/tasks/0'));
    });

    test('const canonicalization for identical literals', () {
      const a = ConfigIssue('x');
      const b = ConfigIssue('x');
      expect(identical(a, b), isTrue);
    });
  });

  group('IssueSeverity', () {
    test('provides expected ordering of values', () {
      expect(
          IssueSeverity.values,
          equals([
            IssueSeverity.info,
            IssueSeverity.warning,
            IssueSeverity.error,
          ]));
    });
  });
}
