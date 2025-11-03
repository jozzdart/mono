import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

class _FakePlugin extends TaskPlugin {
  _FakePlugin(String id) : super(PluginId(id));
  @override
  bool supports(CommandId id) => true;
  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) async =>
      0;
}

void main() {
  group('PluginRegistry', () {
    final pub = _FakePlugin('pub');
    final testPlugin = _FakePlugin('test');
    final registry = PluginRegistry({'pub': pub, 'test': testPlugin});

    test('returns null for null id', () {
      expect(registry.resolve(null), isNull);
    });

    test('resolves known plugin', () {
      expect(registry.resolve(const PluginId('pub')), same(pub));
      expect(registry.resolve(const PluginId('test')), same(testPlugin));
    });

    test('returns null for unknown plugin', () {
      expect(registry.resolve(const PluginId('format')), isNull);
    });
  });
}
