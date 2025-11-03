import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

import '../util/test_doubles.dart';

void main() {
  group('DefaultGraphBuilder', () {
    test('builds empty graph for no packages', () {
      final g = const DefaultGraphBuilder().build(const <MonoPackage>[]);
      expect(g.nodes, isEmpty);
      expect(g.edges, isEmpty);
    });

    test('adds nodes and edges for local dependencies only', () {
      final a = pkg('a');
      final b = pkg('b');
      final c =
          pkg('c', deps: {PackageName('a'), PackageName('x')}); // x ignored
      final d = pkg('d', deps: {PackageName('b'), PackageName('c')});

      final g = const DefaultGraphBuilder().build([a, b, c, d]);
      expect(g.nodes, containsAll(<String>{'a', 'b', 'c', 'd'}));
      expect(g.dependenciesOf('c'), {'a'});
      expect(g.dependenciesOf('d'), {'b', 'c'});
      expect(g.dependenciesOf('a'), isEmpty);
    });
  });
}
