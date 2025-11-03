import 'package:mono_core/mono_core.dart';

@immutable
class FormatPlugin extends TaskPlugin {
  const FormatPlugin() : super(const PluginId('format'));

  static const CommandId formatCmd = CommandId('format');
  static const CommandId formatCheckCmd = CommandId('format:check');

  @override
  bool supports(CommandId commandId) =>
      commandId.value == formatCmd.value ||
      commandId.value == formatCheckCmd.value;

  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) async {
    if (commandId.value == formatCheckCmd.value) {
      return processRunner.run(
        ['dart', 'format', '--output=none', '--set-exit-if-changed', '.'],
        cwd: package.path,
        env: env,
        onStdout: (l) => logger.log(l, scope: package.name.value),
        onStderr: (l) =>
            logger.log(l, scope: package.name.value, level: 'error'),
      );
    }
    // Default: write changes
    return processRunner.run(
      ['dart', 'format', '.'],
      cwd: package.path,
      env: env,
      onStdout: (l) => logger.log(l, scope: package.name.value),
      onStderr: (l) => logger.log(l, scope: package.name.value, level: 'error'),
    );
  }
}
