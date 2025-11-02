import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('CommandEnvironment', () {
    test('constructs with all required fields and preserves values', () {
      final config = MonoConfig(include: const ['**'], exclude: const []);
      final env = CommandEnvironment(
        config: config,
        monocfgPath: 'monocfg',
        packages: const <MonoPackage>[],
        graph: DependencyGraph(nodes: {}, edges: {}),
        groups: const <String, Set<String>>{},
        selector: _DummySelector(),
        effectiveOrder: true,
        effectiveConcurrency: 4,
      );

      expect(env.config, same(config));
      expect(env.monocfgPath, 'monocfg');
      expect(env.packages, isEmpty);
      expect(env.graph.nodes, isEmpty);
      expect(env.graph.edges, isEmpty);
      expect(env.groups, isEmpty);
      expect(env.selector, isA<_DummySelector>());
      expect(env.effectiveOrder, isTrue);
      expect(env.effectiveConcurrency, 4);
    });

    test('builder interface compiles and returns expected shape', () async {
      final builder = _FakeBuilder();
      final env = await builder.build(
        const CliInvocation(commandPath: ['any']),
        groupStoreFactory: (_) => _NoopGroupStore(),
      );

      expect(env.monocfgPath, 'monocfg');
      expect(env.config.include, contains('**'));
      expect(env.packages, isEmpty);
      expect(env.groups, isEmpty);
      expect(env.selector, isA<_DummySelector>());
      expect(env.effectiveOrder, isTrue);
      expect(env.effectiveConcurrency, greaterThanOrEqualTo(1));
    });
  });
}

class _DummySelector implements TargetSelector {
  const _DummySelector();

  @override
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups,
    required DependencyGraph graph,
    required bool dependencyOrder,
  }) {
    return const <MonoPackage>[];
  }
}

class _FakeBuilder extends CommandEnvironmentBuilder {
  const _FakeBuilder();

  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore Function(String monocfgPath) groupStoreFactory,
  }) async {
    return CommandEnvironment(
      config: MonoConfig(include: const ['**'], exclude: const []),
      monocfgPath: 'monocfg',
      packages: const <MonoPackage>[],
      graph: DependencyGraph(nodes: {}, edges: {}),
      groups: const <String, Set<String>>{},
      selector: const _DummySelector(),
      effectiveOrder: true,
      effectiveConcurrency: 1,
    );
  }
}

class _NoopGroupStore implements GroupStore {
  @override
  Future<void> deleteGroup(String groupName) async {}

  @override
  Future<bool> exists(String groupName) async => false;

  @override
  Future<List<String>> listGroups() async => const <String>[];

  @override
  Future<List<String>> readGroup(String groupName) async => const <String>[];

  @override
  Future<void> writeGroup(String groupName, List<String> members) async {}
}
