import 'package:mono_core/mono_core.dart';

class SetupCommand extends Command {
  const SetupCommand();

  @override
  String get name => 'setup';

  @override
  String get description => 'Create base config files and scaffolding';

  @override
  Future<int> run(
    CliContext context,
  ) =>
      runCommand(
        logger: context.logger,
        workspaceConfig: context.workspaceConfig,
      );

  static Future<int> runCommand({
    required Logger logger,
    required WorkspaceConfig workspaceConfig,
  }) async {
    await workspaceConfig.writeRootConfigIfMissing();
    final loaded = await workspaceConfig.loadRootConfig();
    await workspaceConfig.ensureMonocfgScaffold(loaded.monocfgPath);
    await workspaceConfig.writeRootConfigNormalized(logger: logger);
    logger.log(
        'Created/verified mono.yaml and ${loaded.monocfgPath}/ scaffolding');
    return 0;
  }
}
