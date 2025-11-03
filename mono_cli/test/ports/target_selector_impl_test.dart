import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

import '../util/test_doubles.dart';

void main() {
  group('DefaultTargetSelector', () {
    final selector = const DefaultTargetSelector();
    final pkgs = [pkg('app'), pkg('lib1'), pkg('lib2'), pkg('util_test')];
    final graph = DependencyGraph(nodes: {
      for (final p in pkgs) p.name.value
    }, edges: {
      'app': {'lib1'},
      'lib1': {'lib2'},
      'lib2': <String>{},
      'util_test': <String>{},
    });

    test('no expressions selects all; dependencyOrder toggles ordering', () {
      final g = <String, Set<String>>{}; // empty groups
      final noOrder = selector.resolve(
        expressions: const <TargetExpr>[],
        packages: pkgs,
        groups: g,
        graph: graph,
        dependencyOrder: false,
      );
      expect(noOrder.map((p) => p.name.value).toList(),
          ['app', 'lib1', 'lib2', 'util_test']);

      final topo = selector.resolve(
        expressions: const <TargetExpr>[],
        packages: pkgs,
        groups: g,
        graph: graph,
        dependencyOrder: true,
      );
      // Per DependencyGraph semantics, dependents come before their dependencies.
      final names = topo.map((p) => p.name.value).toList();
      expect(names.indexOf('app') < names.indexOf('lib1'), isTrue);
      expect(names.indexOf('lib1') < names.indexOf('lib2'), isTrue);
    });

    test('supports TargetPackage and TargetAll', () {
      final g = <String, Set<String>>{};
      final onlyLib1 = selector.resolve(
        expressions: const <TargetExpr>[TargetPackage('lib1')],
        packages: pkgs,
        groups: g,
        graph: graph,
        dependencyOrder: false,
      );
      expect(onlyLib1.map((p) => p.name.value), ['lib1']);

      final all = selector.resolve(
        expressions: const <TargetExpr>[TargetAll()],
        packages: pkgs,
        groups: g,
        graph: graph,
        dependencyOrder: false,
      );
      expect(all.length, pkgs.length);
    });

    test('group expansion supports nested groups and globs', () {
      final groups = <String, Set<String>>{
        'core': {'lib*'},
        'all': {':core', 'app'},
      };
      final selected = selector.resolve(
        expressions: const <TargetExpr>[TargetGroup('all')],
        packages: pkgs,
        groups: groups,
        graph: graph,
        dependencyOrder: false,
      );
      expect(
        selected.map((p) => p.name.value).toList(),
        containsAllInOrder(['lib1', 'lib2', 'app']),
      );
      // duplicate prevention
      expect(selected.map((p) => p.name.value).toSet().length, selected.length);
    });

    test('glob pattern TargetGlob matches names', () {
      final g = <String, Set<String>>{};
      final selected = selector.resolve(
        expressions: const <TargetExpr>[TargetGlob('lib?')],
        packages: pkgs,
        groups: g,
        graph: graph,
        dependencyOrder: false,
      );
      expect(selected.map((p) => p.name.value).toSet(), {'lib1', 'lib2'});
    });
  });
}
