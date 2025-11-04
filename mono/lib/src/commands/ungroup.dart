import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class UngroupCommand extends Command {
  const UngroupCommand();

  @override
  String get name => 'ungroup';

  @override
  String get description => 'Remove a named group after confirmation';

  @override
  Future<int> run(
    CliContext context,
  ) async {
    final inv = context.invocation;
    final logger = context.logger;
    final prompter = context.prompter;
    if (inv.positionals.isEmpty) {
      logger.log('Usage: mono ungroup <group_name>', level: 'error');
      return 2;
    }
    final groupName = inv.positionals.first.trim();
    if (groupName.isEmpty || groupName.startsWith(':')) {
      logger.log('Invalid group name: "$groupName"', level: 'error');
      return 2;
    }

    final loaded = await context.workspaceConfig.loadRootConfig();
    final store = await FileGroupStore.create(
      pathService: context.pathService,
      loadedRootConfig: loaded,
    );
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

  static Future<int> runCommand({
    required CliInvocation invocation,
    required Logger logger,
    required Prompter prompter,
    required GroupStore store,
  }) async {
    final inv = invocation;

    if (inv.positionals.isEmpty) {
      logger.log('Usage: mono ungroup <group_name>', level: 'error');
      return 2;
    }
    final groupName = inv.positionals.first.trim();
    if (groupName.isEmpty || groupName.startsWith(':')) {
      logger.log('Invalid group name: "$groupName"', level: 'error');
      return 2;
    }

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
