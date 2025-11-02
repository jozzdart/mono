import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

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

class _MapResolver extends PluginResolver {
  _MapResolver(this._map);
  final Map<String, TaskPlugin> _map;
  @override
  TaskPlugin? resolve(PluginId? id) => id == null ? null : _map[id.value];
}

void main() {
  group('PluginResolver contract', () {
    final pub = _FakePlugin('pub');
    final format = _FakePlugin('format');
    final resolver = _MapResolver({'pub': pub, 'format': format});

    test('returns null when id is null', () {
      expect(resolver.resolve(null), isNull);
    });

    test('returns plugin for known id', () {
      expect(resolver.resolve(const PluginId('pub')), same(pub));
      expect(resolver.resolve(const PluginId('format')), same(format));
    });

    test('returns null for unknown id', () {
      expect(resolver.resolve(const PluginId('missing')), isNull);
    });

    test('id equality by value works', () {
      expect(resolver.resolve(const PluginId('pub')), same(pub));
      expect(resolver.resolve(const PluginId('pub')), same(pub));
    });
  });
}
