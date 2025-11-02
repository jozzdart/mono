import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class SimplePrompter implements Prompter {
  const SimplePrompter();
  @override
  Future<bool> confirm(String message, {bool defaultValue = false}) async =>
      defaultValue;

  @override
  Future<List<int>> checklist({
    required String title,
    required List<String> items,
  }) async {
    if (items.isEmpty) return const <int>[];
    if (items.length == 1) return const <int>[0];
    return <int>[0, items.length - 1];
  }
}

class CatalogPackageScanner implements PackageScanner {
  CatalogPackageScanner(this.catalog);
  final List<MonoPackage> catalog;

  @override
  Future<List<MonoPackage>> scan({
    required String rootPath,
    required List<String> includeGlobs,
    required List<String> excludeGlobs,
  }) async {
    bool matchesIncludes(String path) =>
        includeGlobs.isEmpty || includeGlobs.any((g) => path.contains(g));
    bool matchesExcludes(String path) =>
        excludeGlobs.any((g) => path.contains(g));

    return catalog
        .where((p) => p.path.startsWith(rootPath))
        .where((p) => matchesIncludes(p.path))
        .where((p) => !matchesExcludes(p.path))
        .toList();
  }
}

class RecordingLogger implements Logger {
  final List<({String message, String? scope, String level})> records = [];
  @override
  void log(String message, {String? scope, String level = 'info'}) {
    records.add((message: message, scope: scope, level: level));
  }
}

class StubProcessRunner implements ProcessRunner {
  final List<List<String>> commands = [];
  @override
  Future<int> run(
    List<String> command, {
    String? cwd,
    Map<String, String>? env,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    commands.add(List<String>.from(command));
    onStdout?.call('ok');
    return 0;
  }
}

class FakeTaskPlugin extends TaskPlugin {
  FakeTaskPlugin() : super(const PluginId('fake'));

  @override
  bool supports(CommandId commandId) => commandId.value == 'build';

  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) async {
    logger.log('executing', scope: id.value);
    await processRunner.run(['echo', '${id.value}:${commandId.value}']);
    return 0;
  }
}

class SimpleVersionInfo implements VersionInfo {
  const SimpleVersionInfo({required this.name, required this.version});
  @override
  final String name;
  @override
  final String version;
}

MonoPackage pkg(String name) => MonoPackage(
      name: PackageName(name),
      path: '/repo/$name',
      kind: PackageKind.dart,
    );

void main() {
  group('Prompter', () {
    test('confirm returns provided defaultValue', () async {
      const p = SimplePrompter();
      expect(await p.confirm('Are you sure?'), isFalse);
      expect(await p.confirm('Are you sure?', defaultValue: true), isTrue);
    });

    test('checklist returns valid indices', () async {
      const p = SimplePrompter();
      final r = await p.checklist(title: 'Pick', items: ['a', 'b', 'c']);
      expect(r, [0, 2]);
    });
  });

  group('PackageScanner', () {
    test('filters by include and exclude globs (contains)', () async {
      final scanner = CatalogPackageScanner([
        pkg('ui').copyWith(path: '/repo/packages/ui'),
        pkg('data').copyWith(path: '/repo/packages/data'),
        pkg('tool').copyWith(path: '/repo/tools/tool'),
      ]);

      final r = await scanner.scan(
        rootPath: '/repo',
        includeGlobs: ['packages'],
        excludeGlobs: ['data'],
      );
      expect(r.map((p) => p.name.value).toList(), ['ui']);
    });
  });

  group('TaskPlugin', () {
    test('supports and execute', () async {
      final plugin = FakeTaskPlugin();
      final logger = RecordingLogger();
      final runner = StubProcessRunner();
      final pkgA = pkg('a');

      expect(plugin.id, const PluginId('fake'));
      expect(plugin.supports(const CommandId('build')), isTrue);
      expect(plugin.supports(const CommandId('test')), isFalse);

      final code = await plugin.execute(
        commandId: const CommandId('build'),
        package: pkgA,
        processRunner: runner,
        logger: logger,
        env: const {'K': 'V'},
      );
      expect(code, 0);
      expect(logger.records.single.scope, 'fake');
      expect(runner.commands.single, ['echo', 'fake:build']);
    });
  });

  group('VersionInfo', () {
    test('exposes name and version', () {
      const v = SimpleVersionInfo(name: 'mono', version: '1.2.3');
      expect(v.name, 'mono');
      expect(v.version, '1.2.3');
    });
  });
}
