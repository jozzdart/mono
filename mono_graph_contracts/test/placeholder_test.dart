import 'package:mono_graph_contracts/mono_graph_contracts.dart';
import 'package:test/test.dart';

void main() {
  test('graph contracts load', () {
    final g = DependencyGraph(nodes: {'a'}, edges: {'a': {}});
    expect(g.nodes.contains('a'), isTrue);
  });
}

