import 'package:mono_cli/mono_cli.dart';

class UngroupCommand {
  static Future<int> run({
    required CliInvocation inv,
    required Logger logger,
    required Prompter prompter,
    required WorkspaceConfig workspaceConfig,
    GroupStore Function(String monocfgPath)? groupStoreFactory,
  }) async {
    if (inv.positionals.isEmpty) {
      logger.log('Usage: mono ungroup <group_name>', level: 'error');
      return 2;
    }
    final groupName = inv.positionals.first.trim();
    if (groupName.isEmpty || groupName.startsWith(':')) {
      logger.log('Invalid group name: "$groupName"', level: 'error');
      return 2;
    }

    final loaded = await workspaceConfig.loadRootConfig();
    final store = (groupStoreFactory ??
        (String monocfgPath) {
          final groupsPath =
              const DefaultPathService().join([monocfgPath, 'groups']);
          final folder = FileListConfigFolder(
            basePath: groupsPath,
            namePolicy: const DefaultSlugNamePolicy(),
          );
          return FileGroupStore(folder);
        })(loaded.monocfgPath);
    if (!await store.exists(groupName)) {
      logger.log('Group "$groupName" does not exist.', level: 'error');
      return 2;
    }

    final ok = await prompter.confirm(
      'Remove group "$groupName"? This cannot be undone.',
      defaultValue: false,
    );
    if (!ok) {
      logger.log('Aborted.', level: 'error');
      return 1;
    }

    await store.deleteGroup(groupName);
    logger.log('Group "$groupName" removed.');
    return 0;
  }
}
