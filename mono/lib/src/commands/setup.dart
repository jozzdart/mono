import 'package:mono_core/mono_core.dart';

class SetupCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required Logger logger,
      required WorkspaceConfig workspaceConfig}) async {
    await workspaceConfig.writeRootConfigIfMissing();
    final loaded = await workspaceConfig.loadRootConfig();
    await workspaceConfig.ensureMonocfgScaffold(loaded.monocfgPath);
    logger.log(
        'Created/verified mono.yaml and ${loaded.monocfgPath}/ scaffolding');
    return 0;
  }
}
