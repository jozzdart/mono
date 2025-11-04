import 'package:mono_cli/mono_cli.dart' hide equals;
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

class _BufferingLogger implements Logger {
  _BufferingLogger(this.out, this.err);
  final StringBuffer out;
  final StringBuffer err;
  @override
  void log(String message, {String? scope, String level = 'info'}) {
    if (level == 'error') {
      err.writeln(message);
    } else {
      out.writeln(message);
    }
  }
}

class _EnvBuilderEmpty implements CommandEnvironmentBuilder {
  const _EnvBuilderEmpty();
  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore groupStore,
  }) async {
    return CommandEnvironment(
      config: const MonoConfig(include: [], exclude: []),
      monocfgPath: 'monocfg',
      packages: const [],
      graph: DependencyGraph(nodes: const {}),
      groups: const {},
      selector: const DefaultTargetSelector(),
      effectiveOrder: true,
      effectiveConcurrency: 1,
    );
  }
}

class _EnvBuilderSingle implements CommandEnvironmentBuilder {
  const _EnvBuilderSingle({this.selector = const DefaultTargetSelector()});
  final TargetSelector selector;

  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore groupStore,
  }) async {
    final pkg = MonoPackage(
      name: const PackageName('a'),
      path: '/a',
      kind: PackageKind.dart,
    );
    return CommandEnvironment(
      config: const MonoConfig(include: [], exclude: []),
      monocfgPath: 'monocfg',
      packages: [pkg],
      graph: DependencyGraph(nodes: {'a'}),
      groups: const {},
      selector: selector,
      effectiveOrder: true,
      effectiveConcurrency: 1,
    );
  }
}

class _SelectorNone implements TargetSelector {
  const _SelectorNone();
  @override
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups,
    required DependencyGraph graph,
    required bool dependencyOrder,
  }) =>
      const [];
}

class _FakePlugin implements TaskPlugin {
  _FakePlugin(this.id);
  @override
  final PluginId id;
  final List<Map<String, String>> recordedEnv = [];
  @override
  bool supports(CommandId commandId) => true;
  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) async {
    recordedEnv.add(Map.of(env));
    return 0;
  }
}

class _Plugins implements PluginResolver {
  _Plugins(this._plugin);
  final TaskPlugin _plugin;
  @override
  TaskPlugin? resolve(PluginId? id) => _plugin;
}

GroupStore groupStore = FileGroupStore(
  FileListConfigFolder(basePath: 'monocfg/groups'),
);

void main() {
  group('DefaultTaskExecutor', () {
    test('empty workspace prints message and returns 1', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final exec = const DefaultTaskExecutor();
      final code = await exec.execute(
        task:
            TaskSpec(id: const CommandId('get'), plugin: const PluginId('pub')),
        invocation: const CliInvocation(commandPath: ['get']),
        logger: _BufferingLogger(outB, errB),
        groupStore: groupStore,
        envBuilder: const _EnvBuilderEmpty(),
        plugins: PluginRegistry({}),
      );
      expect(code, 1);
      expect(errB.toString(),
          contains('No packages found. Run `mono scan` first.'));
    });

    test('dry-run uses provided dryRunLabel', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final exec = const DefaultTaskExecutor();
      final code = await exec.execute(
        task: TaskSpec(
            id: const CommandId('exec:echo hi'),
            plugin: const PluginId('exec')),
        invocation: const CliInvocation(
          commandPath: ['build'],
          options: {
            'dry-run': ['1']
          },
          targets: [TargetAll()],
        ),
        logger: _BufferingLogger(outB, errB),
        groupStore: groupStore,
        envBuilder: const _EnvBuilderSingle(),
        plugins: PluginRegistry({}),
        dryRunLabel: 'build',
      );
      expect(code, 0);
      expect(outB.toString(),
          contains('Would run build for 1 packages in dependency order.'));
      expect(errB.toString().trim(), isEmpty);
    });

    test('selector producing no targets returns 1 with message', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final exec = const DefaultTaskExecutor();
      final code = await exec.execute(
        task:
            TaskSpec(id: const CommandId('get'), plugin: const PluginId('pub')),
        invocation: const CliInvocation(
          commandPath: ['get'],
          targets: [TargetAll()],
        ),
        logger: _BufferingLogger(outB, errB),
        groupStore: groupStore,
        envBuilder: const _EnvBuilderSingle(selector: _SelectorNone()),
        plugins: PluginRegistry({}),
      );
      expect(code, 1);
      expect(errB.toString(), contains('No target packages matched.'));
    });

    test('runs plugin with env and returns aggregate code', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final plugin = _FakePlugin(const PluginId('exec'));
      final exec = const DefaultTaskExecutor();
      final code = await exec.execute(
        task: TaskSpec(
            id: const CommandId('exec:noop'), plugin: const PluginId('exec')),
        invocation: const CliInvocation(
          commandPath: ['noop'],
          targets: [TargetAll()],
        ),
        logger: _BufferingLogger(outB, errB),
        groupStore: groupStore,
        envBuilder: const _EnvBuilderSingle(),
        plugins: _Plugins(plugin),
        env: const {'FOO': 'BAR'},
      );
      expect(code, 0);
      expect(plugin.recordedEnv.single, equals(const {'FOO': 'BAR'}));
    });
  });
}
