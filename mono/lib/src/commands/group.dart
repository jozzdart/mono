import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import '../config_io.dart';

class GroupCommand {
  static Future<int> run({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required Prompter prompter,
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

    // Conflict checks
    if (loaded.config.groups.containsKey(groupName)) {
      err.writeln('Group "$groupName" already exists.');
      return 2;
    }
    if (packageNames.contains(groupName)) {
      err.writeln('Cannot create group with same name as a package: "$groupName"');
      return 2;
    }

    // Interactive checklist
    final indices = await prompter.checklist(
      title: 'Select packages for group "$groupName"',
      items: packageNames,
    );
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

    final updated = <String, List<String>>{
      for (final e in loaded.config.groups.entries) e.key: List<String>.from(e.value),
    };
    updated[groupName] = members;

    await writeRootConfigGroups('mono.yaml', updated);
    out.writeln('Group "$groupName" created with ${members.length} member(s).');
    return 0;
  }
}


