import 'package:mono_core/mono_core.dart';

class PluginRegistry implements PluginResolver {
  const PluginRegistry(this._plugins);
  final Map<String, TaskPlugin> _plugins; // id.value -> plugin

  @override
  TaskPlugin? resolve(PluginId? id) {
    if (id == null) return null;
    return _plugins[id.value];
  }
}
