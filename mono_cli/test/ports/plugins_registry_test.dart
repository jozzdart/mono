import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';

import '../util/test_doubles.dart';

void main() {
  group('PluginRegistry', () {
    test('resolves plugin by id value and returns null for null id', () {
      final p1 = TestTaskPlugin('x');
      final p2 = TestTaskPlugin('y');
      final reg = PluginRegistry({'x': p1, 'y': p2});
      expect(reg.resolve(const PluginId('x')), same(p1));
      expect(reg.resolve(const PluginId('y')), same(p2));
      expect(reg.resolve(const PluginId('z')), isNull);
      expect(reg.resolve(null), isNull);
    });
  });
}
