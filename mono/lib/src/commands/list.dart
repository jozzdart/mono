import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class ListCommand extends Command {
  const ListCommand();

  @override
  String get name => 'list';

  @override
  String get description => 'List packages | groups | tasks';

  @override
  Future<int> run(
    CliContext context,
  ) async =>
      await runCommand(
        invocation: context.invocation,
        logger: context.logger,
        workspaceConfig: context.workspaceConfig,
        packageScanner: context.packageScanner,
        groupStore: await FileGroupStore.createFromContext(context),
      );

  static Future<int> runCommand({
    required CliInvocation invocation,
    required Logger logger,
    required WorkspaceConfig workspaceConfig,
    required PackageScanner packageScanner,
    required GroupStore groupStore,
  }) async {
    final inv = invocation;
    final what =
        inv.positionals.isNotEmpty ? inv.positionals.first : 'packages';
    final loaded = await workspaceConfig.loadRootConfig();
    if (what == 'packages') {
      final projects =
          await workspaceConfig.readMonocfgProjects(loaded.monocfgPath);
      if (projects.isEmpty) {
        // Fallback to a quick scan if no cache yet
        final pkgs = await packageScanner.scan(
          rootPath: Directory.current.path,
          includeGlobs: loaded.config.include,
          excludeGlobs: loaded.config.exclude,
        );
        for (final p in pkgs) {
          final kind = p.kind.name;
          logger.log('- ${p.name.value} → ${p.path} ($kind)');
        }
      } else {
        for (final p in projects) {
          logger.log('- ${p.name} → ${p.path} (${p.kind})');
        }
      }
      return 0;
    }
    if (what == 'groups') {
      final store = groupStore;
      final names = await store.listGroups();
      for (final name in names) {
        final members = await store.readGroup(name);
        logger.log('- $name → ${members.join(', ')}');
      }
      return 0;
    }
    if (what == 'tasks') {
      final merged = <String, Map<String, Object?>>{};
      for (final e in loaded.config.tasks.entries) {
        merged[e.key] = {
          if (e.value.plugin != null) 'plugin': e.value.plugin,
          if (e.value.dependsOn.isNotEmpty) 'dependsOn': e.value.dependsOn,
          if (e.value.env.isNotEmpty) 'env': e.value.env,
          if (e.value.run.isNotEmpty) 'run': e.value.run,
        };
      }
      final extra = await workspaceConfig.readMonocfgTasks(loaded.monocfgPath);
      merged.addAll(extra);
      for (final e in merged.entries) {
        final plugin = (e.value['plugin'] ?? 'exec').toString();
        logger.log('- ${e.key} (plugin: $plugin)');
      }
      return 0;
    }
    logger.log('Unknown list target: $what', level: 'error');
    return 1;
  }
}
