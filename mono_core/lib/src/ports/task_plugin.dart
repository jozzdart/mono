import 'package:mono_core/mono_core.dart';

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
