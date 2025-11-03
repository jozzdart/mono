import 'dart:io';

import 'package:mono_core/mono_core.dart';

class GroupCommand {
  static Future<int> run({
    required CliInvocation inv,
    required Logger logger,
    required Prompter prompter,
    required WorkspaceConfig workspaceConfig,
    required PackageScanner packageScanner,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
  }) async {
    if (inv.positionals.isEmpty) {
      logger.log('Usage: mono group <group_name>', level: 'error');
      return 2;
    }
    final groupName = inv.positionals.first.trim();
    if (groupName.isEmpty || groupName.startsWith(':')) {
      logger.log('Invalid group name: "$groupName"', level: 'error');
      return 2;
    }

    final loaded = await workspaceConfig.loadRootConfig();
    final store = groupStoreFactory(loaded.monocfgPath);

    // Load packages from cache or fallback scanner
    final projects =
        await workspaceConfig.readMonocfgProjects(loaded.monocfgPath);
    List<String> packageNames;
    if (projects.isEmpty) {
      final pkgs = await packageScanner.scan(
        rootPath: Directory.current.path,
        includeGlobs: loaded.config.include,
        excludeGlobs: loaded.config.exclude,
      );
      packageNames = [for (final p in pkgs) p.name.value];
    } else {
      packageNames = [for (final p in projects) p.name];
    }
    packageNames.sort();

    // Conflict checks (file-based)
    if (await store.exists(groupName)) {
      final ok = await prompter.confirm(
          'Group "$groupName" already exists. Overwrite?',
          defaultValue: false);
      if (!ok) {
        logger.log('Aborted.', level: 'error');
        return 1;
      }
    }
    if (packageNames.contains(groupName)) {
      logger.log(
          'Cannot create group with same name as a package: "$groupName"',
          level: 'error');
      return 2;
    }

    // Interactive checklist
    List<int> indices;
    try {
      indices = await prompter.checklist(
        title: 'Select packages for group "$groupName"',
        items: packageNames,
      );
    } on SelectionError {
      logger.log('Aborted.', level: 'error');
      return 1;
    }
    if (indices.isEmpty) {
      final ok = await prompter.confirm(
          'No packages selected. Create empty group "$groupName"?',
          defaultValue: false);
      if (!ok) {
        logger.log('Aborted.', level: 'error');
        return 1;
      }
    }
    final members = [for (final i in indices) packageNames[i]];
    await store.writeGroup(groupName, members);
    logger.log('Group "$groupName" saved with ${members.length} member(s).');
    return 0;
  }
}
