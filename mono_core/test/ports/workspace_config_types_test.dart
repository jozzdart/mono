import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorkspaceConfig types', () {
    test('PackageRecord stores fields', () {
      const r = PackageRecord(name: 'a', path: 'packages/a', kind: 'dart');
      expect(r.name, 'a');
      expect(r.path, 'packages/a');
      expect(r.kind, 'dart');
    });

    test('LoadedRootConfig stores fields', () {
      const settings = Settings();
      const cfg = MonoConfig(
        include: ['**'],
        exclude: [],
        dartProjects: {'a': 'packages/a'},
        groups: {
          'g': ['a']
        },
        tasks: {},
        settings: settings,
      );
      const loaded = LoadedRootConfig(
        config: cfg,
        monocfgPath: 'monocfg',
        rawYaml: 'settings: {}',
      );
      expect(loaded.config.include, contains('**'));
      expect(loaded.monocfgPath, 'monocfg');
      expect(loaded.rawYaml, contains('settings'));
    });
  });
}
