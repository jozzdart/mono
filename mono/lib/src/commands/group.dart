import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import '../config_io.dart';

class GroupCommand {
  static Future<int> run({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required Prompter prompter,
    GroupStore Function(String monocfgPath)? groupStoreFactory,
  }) async {
    if (inv.positionals.isEmpty) {
      err.writeln('Usage: mono group <group_name>');
      return 2;
    }
    final groupName = inv.positionals.first.trim();
    if (groupName.isEmpty || groupName.startsWith(':')) {
      err.writeln('Invalid group name: "$groupName"');
      return 2;
    }

    final loaded = await loadRootConfig();
    final store = (groupStoreFactory ?? (String monocfgPath) {
      final groupsPath = const DefaultPathService().join([monocfgPath, 'groups']);
      final folder = FileListConfigFolder(
        basePath: groupsPath,
        namePolicy: const DefaultSlugNamePolicy(),
      );
      return FileGroupStore(folder);
    })(loaded.monocfgPath);

    // Load packages from cache or fallback scanner
    final projects = await readMonocfgProjects(loaded.monocfgPath);
    List<String> packageNames;
    if (projects.isEmpty) {
      final scanner = const FileSystemPackageScanner();
      final pkgs = await scanner.scan(
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
        err.writeln('Aborted.');
        return 1;
      }
    }
    if (packageNames.contains(groupName)) {
      err.writeln('Cannot create group with same name as a package: "$groupName"');
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
      err.writeln('Aborted.');
      return 1;
    }
    if (indices.isEmpty) {
      final ok = await prompter.confirm(
          'No packages selected. Create empty group "$groupName"?',
          defaultValue: false);
      if (!ok) {
        err.writeln('Aborted.');
        return 1;
      }
    }
    final members = [for (final i in indices) packageNames[i]];
    await store.writeGroup(groupName, members);
    out.writeln('Group "$groupName" saved with ${members.length} member(s).');
    return 0;
  }
}


