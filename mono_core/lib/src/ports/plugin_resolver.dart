import 'package:mono_core/mono_core.dart';

abstract class PluginResolver {
  const PluginResolver();
  TaskPlugin? resolve(PluginId? id);
}
