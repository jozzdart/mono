import 'package:mono_cli/mono_cli.dart';

@immutable
class TestPlugin extends TaskPlugin {
  TestPlugin() : super(const PluginId('test'));

  static const CommandId testCmd = CommandId('test');

  @override
  bool supports(CommandId commandId) => commandId.value == testCmd.value;

  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) async {
    final isFlutter = package.kind == PackageKind.flutter;
    final exe = isFlutter ? 'flutter' : 'dart';
    final args = <String>['test'];
    return processRunner.run(
      [exe, ...args],
      cwd: package.path,
      env: env,
      onStdout: (l) => logger.log(l, scope: package.name.value),
      onStderr: (l) => logger.log(l, scope: package.name.value, level: 'error'),
    );
  }
}
