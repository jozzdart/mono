import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class SimpleTargetSelector implements TargetSelector {
  const SimpleTargetSelector();

  @override
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups,
    required DependencyGraph graph,
    required bool dependencyOrder,
  }) {
    final byName = {for (final p in packages) p.name.value: p};
    final selectedNames = <String>{};
    for (final expr in expressions) {
      if (expr is TargetAll) {
        selectedNames.addAll(byName.keys);
      } else if (expr is TargetPackage) {
        if (byName.containsKey(expr.name)) selectedNames.add(expr.name);
      } else if (expr is TargetGroup) {
        selectedNames.addAll(groups[expr.groupName] ?? const <String>{});
      } else if (expr is TargetGlob) {
        for (final name in byName.keys) {
          if (name.contains(expr.pattern)) selectedNames.add(name);
        }
      }
    }

    Iterable<String> orderNames;
    if (dependencyOrder) {
      final topo = graph.topologicalOrder();
      orderNames = topo.where(selectedNames.contains);
    } else {
      orderNames =
          packages.map((p) => p.name.value).where(selectedNames.contains);
    }
    return [for (final n in orderNames) byName[n]!];
  }
}

MonoPackage pkg(String name, {Set<String> deps = const {}}) => MonoPackage(
      name: PackageName(name),
      path: 'packages/$name',
      kind: PackageKind.dart,
      localDependencies: deps.map((d) => PackageName(d)).toSet(),
    );

DependencyGraph graphFrom(List<MonoPackage> packages) {
  final nodes = {for (final p in packages) p.name.value};
  final edges = <String, Set<String>>{};
  for (final p in packages) {
    edges[p.name.value] = p.localDependencies.map((d) => d.value).toSet();
  }
  return DependencyGraph(nodes: nodes, edges: edges);
}

void main() {
  group('TargetSelector', () {
    test('respects dependency order when enabled', () {
      const selector = SimpleTargetSelector();
      final a = pkg('a', deps: {'b'});
      final b = pkg('b');
      final packages = [a, b];
      final graph = graphFrom(packages);
      final result = selector.resolve(
        expressions: const [TargetAll()],
        packages: packages,
        groups: const {},
        graph: graph,
        dependencyOrder: true,
      );
      expect(result.map((p) => p.name.value).toList(), ['a', 'b']);
    });

    test('keeps input order when dependency order is disabled', () {
      const selector = SimpleTargetSelector();
      final a = pkg('a', deps: {'b'});
      final b = pkg('b');
      final packages = [a, b];
      final graph = graphFrom(packages);
      final result = selector.resolve(
        expressions: const [TargetAll()],
        packages: packages,
        groups: const {},
        graph: graph,
        dependencyOrder: false,
      );
      expect(result.map((p) => p.name.value).toList(), ['a', 'b']);
    });

    test('supports package and group expressions', () {
      const selector = SimpleTargetSelector();
      final a = pkg('app');
      final b = pkg('core');
      final packages = [a, b];
      final graph = graphFrom(packages);
      final groups = {
        'g1': {'app'},
      };

      final r1 = selector.resolve(
        expressions: const [TargetPackage('core')],
        packages: packages,
        groups: groups,
        graph: graph,
        dependencyOrder: false,
      );
      expect(r1.single.name.value, 'core');

      final r2 = selector.resolve(
        expressions: const [TargetGroup('g1')],
        packages: packages,
        groups: groups,
        graph: graph,
        dependencyOrder: false,
      );
      expect(r2.single.name.value, 'app');
    });

    test('supports glob-like substring matches', () {
      const selector = SimpleTargetSelector();
      final a = pkg('ui');
      final b = pkg('data');
      final c = pkg('utils');
      final packages = [a, b, c];
      final graph = graphFrom(packages);
      final r = selector.resolve(
        expressions: const [TargetGlob('u')],
        packages: packages,
        groups: const {},
        graph: graph,
        dependencyOrder: false,
      );
      expect(r.map((p) => p.name.value), containsAll(['ui', 'utils']));
    });
  });
}
