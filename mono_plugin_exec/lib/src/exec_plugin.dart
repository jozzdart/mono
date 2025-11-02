import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_ports/mono_ports.dart';

@immutable
class ExecPlugin extends TaskPlugin {
  ExecPlugin() : super(const PluginId('exec'));

  @override
  bool supports(CommandId commandId) => commandId.value.startsWith('exec:');

  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) async {
    final cmd = commandId.value.substring('exec:'.length);
    final parts = cmd.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 0;
    return processRunner.run(parts, cwd: package.path, env: env,
        onStdout: (l) => logger.log(l, scope: package.name.value),
        onStderr: (l) => logger.log(l, scope: package.name.value, level: 'error'));
  }
}


