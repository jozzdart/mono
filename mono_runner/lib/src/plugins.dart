import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_ports/mono_ports.dart';

class PluginRegistry {
  PluginRegistry(this._plugins);
  final Map<String, TaskPlugin> _plugins; // id.value -> plugin

  TaskPlugin? resolve(PluginId? id) {
    if (id == null) return null;
    return _plugins[id.value];
  }
}


