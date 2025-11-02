import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_ports/mono_ports.dart';

@immutable
abstract class TaskPlugin {
  const TaskPlugin(this.id);
  final PluginId id;
  bool supports(CommandId commandId);
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env,
  });
}


