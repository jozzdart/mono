import 'package:mono_cli/mono_cli.dart';

class PluginRegistry implements PluginResolver {
  PluginRegistry(this._plugins);
  final Map<String, TaskPlugin> _plugins; // id.value -> plugin

  @override
  TaskPlugin? resolve(PluginId? id) {
    if (id == null) return null;
    return _plugins[id.value];
  }
}
