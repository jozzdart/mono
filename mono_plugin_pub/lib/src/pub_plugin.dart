import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_ports/mono_ports.dart';

@immutable
class PubPlugin extends TaskPlugin {
  PubPlugin() : super(const PluginId('pub'));

  static const CommandId getCmd = CommandId('get');
  static const CommandId cleanCmd = CommandId('clean');

  @override
  bool supports(CommandId commandId) =>
      commandId.value == getCmd.value || commandId.value == cleanCmd.value;

  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) async {
    if (commandId.value == getCmd.value) {
      final exe = package.kind == PackageKind.flutter ? 'flutter' : 'dart';
      final args = package.kind == PackageKind.flutter
          ? <String>['pub', 'get']
          : <String>['pub', 'get'];
      return processRunner.run([exe, ...args], cwd: package.path, env: env,
          onStdout: (l) => logger.log(l, scope: package.name.value),
          onStderr: (l) => logger.log(l, scope: package.name.value, level: 'error'));
    }
    if (commandId.value == cleanCmd.value) {
      if (package.kind == PackageKind.flutter) {
        return processRunner.run(['flutter', 'clean'], cwd: package.path, env: env,
            onStdout: (l) => logger.log(l, scope: package.name.value),
            onStderr: (l) => logger.log(l, scope: package.name.value, level: 'error'));
      }
      // No-op for pure Dart for now; succeed.
      logger.log('Nothing to clean for Dart package', scope: package.name.value);
      return 0;
    }
    return 127;
  }
}


