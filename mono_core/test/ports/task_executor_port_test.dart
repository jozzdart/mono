import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class _NoopLogger implements Logger {
  const _NoopLogger();
  @override
  void log(String message, {String? scope, String level = 'info'}) {}
}

class _FakeEnvBuilder implements CommandEnvironmentBuilder {
  const _FakeEnvBuilder(this._env);
  final CommandEnvironment _env;
  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore groupStore,
  }) async {
    return _env;
  }
}

class _FakeGroupStore implements GroupStore {
  const _FakeGroupStore();
  @override
  Future<bool> exists(String groupName) async => false;
  @override
  Future<void> deleteGroup(String groupName) async {}
  @override
  Future<List<String>> listGroups() async => const [];
  @override
  Future<List<String>> readGroup(String groupName) async => const [];
  @override
  Future<void> writeGroup(String groupName, List<String> members) async {}
}

class _FakeSelector implements TargetSelector {
  const _FakeSelector();
  @override
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups,
    required DependencyGraph graph,
    required bool dependencyOrder,
  }) =>
      packages;
}

class _FakePlugins implements PluginResolver {
  const _FakePlugins();
  @override
  TaskPlugin? resolve(PluginId? id) => null;
}

class _ProbeExecutor implements TaskExecutor {
  const _ProbeExecutor();
  static Map<String, Object?> lastArgs = {};
  @override
  Future<int> execute({
    required TaskSpec task,
    required CliInvocation invocation,
    required Logger logger,
    required GroupStore groupStore,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    Map<String, String> env = const {},
    String? dryRunLabel,
  }) async {
    lastArgs = {
      'task': task,
      'inv': invocation,
      'env': env,
      'dryRunLabel': dryRunLabel,
    };
    return 42;
  }
}

void main() {
  group('TaskExecutor port', () {
    test('execute forwards env and dryRunLabel, returns code', () async {
      final task =
          TaskSpec(id: const CommandId('x'), plugin: const PluginId('p'));
      final inv = const CliInvocation(commandPath: ['x']);

      final env = CommandEnvironment(
        config: const MonoConfig(include: [], exclude: []),
        monocfgPath: 'monocfg',
        packages: const [],
        graph: DependencyGraph(nodes: const {}),
        groups: const {},
        selector: const _FakeSelector(),
        effectiveOrder: true,
        effectiveConcurrency: 1,
      );

      final code = await const _ProbeExecutor().execute(
        task: task,
        invocation: inv,
        logger: const _NoopLogger(),
        groupStore: const _FakeGroupStore(),
        envBuilder: _FakeEnvBuilder(env),
        plugins: const _FakePlugins(),
        env: const {'A': 'B'},
        dryRunLabel: 'label',
      );

      expect(code, 42);
      expect(_ProbeExecutor.lastArgs['task'], equals(task));
      expect(_ProbeExecutor.lastArgs['inv'], equals(inv));
      expect(_ProbeExecutor.lastArgs['env'], equals(const {'A': 'B'}));
      expect(_ProbeExecutor.lastArgs['dryRunLabel'], equals('label'));
    });
  });
}
