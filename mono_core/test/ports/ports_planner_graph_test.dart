import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class FakeExecutionPlan extends ExecutionPlan {
  const FakeExecutionPlan({required this.task, required this.targets});
  final TaskSpec task;
  final List<MonoPackage> targets;
}

class FakeCommandPlanner implements CommandPlanner {
  const FakeCommandPlanner();
  @override
  ExecutionPlan plan({
    required TaskSpec task,
    required List<MonoPackage> targets,
  }) {
    return FakeExecutionPlan(
        task: task, targets: List<MonoPackage>.from(targets));
  }
}

class SimpleGraphBuilder implements GraphBuilder {
  const SimpleGraphBuilder();
  @override
  DependencyGraph build(List<MonoPackage> packages) {
    final nodes = <String>{for (final p in packages) p.name.value};
    final edges = <String, Set<String>>{};
    for (final p in packages) {
      edges[p.name.value] = p.localDependencies.map((d) => d.value).toSet();
    }
    return DependencyGraph(nodes: nodes, edges: edges);
  }
}

MonoPackage pkg(String name, {Set<String> deps = const {}}) => MonoPackage(
      name: PackageName(name),
      path: 'packages/$name',
      kind: PackageKind.dart,
      localDependencies: deps.map((d) => PackageName(d)).toSet(),
    );

void main() {
  group('CommandPlanner', () {
    test('returns an ExecutionPlan for given task and targets', () {
      const planner = FakeCommandPlanner();
      final task = TaskSpec(id: CommandId('build'));
      final targets = [pkg('a'), pkg('b')];
      final plan = planner.plan(task: task, targets: targets);
      expect(plan, isA<FakeExecutionPlan>());
      final p = plan as FakeExecutionPlan;
      expect(p.task, task);
      expect(p.targets, targets);
    });
  });

  group('GraphBuilder', () {
    test('builds graph from package localDependencies', () {
      const builder = SimpleGraphBuilder();
      final a = pkg('a', deps: {'b'});
      final b = pkg('b');
      final graph = builder.build([a, b]);
      expect(graph.nodes, {'a', 'b'});
      expect(graph.dependenciesOf('a'), {'b'});
      expect(graph.dependenciesOf('b'), isEmpty);
      expect(graph.topologicalOrder().first, 'a');
    });
  });
}
