import 'package:mono_core/mono_core.dart';
import 'package:mono_cli/mono_cli.dart';

class VersionCommand extends Command {
  const VersionCommand();

  @override
  String get name => 'version';

  @override
  String get description => 'Print the mono version';

  @override
  List<String> get aliases => const ['--version', '-v', '--v'];

  @override
  Future<int> run(
    CliContext context,
  ) =>
      runCommand(
        logger: context.logger,
        packageName: 'mono',
        versionResolver: VersionResolver().resolvePackageVersion,
      );

  static Future<int> runCommand({
    required Logger logger,
    required String packageName,
    required Future<String> Function(String packageName) versionResolver,
  }) async {
    final version = await versionResolver(packageName);

    logger.log('$packageName $version');

    return 0;
  }
}
