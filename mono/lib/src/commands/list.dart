import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import '../config_io.dart';

class ListCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required IOSink out,
      required IOSink err,
      GroupStore Function(String monocfgPath)? groupStoreFactory}) async {
    final what =
        inv.positionals.isNotEmpty ? inv.positionals.first : 'packages';
    final loaded = await loadRootConfig();
    if (what == 'packages') {
      final projects = await readMonocfgProjects(loaded.monocfgPath);
      if (projects.isEmpty) {
        // Fallback to a quick scan if no cache yet
        final scanner = const FileSystemPackageScanner();
        final pkgs = await scanner.scan(
          rootPath: Directory.current.path,
          includeGlobs: loaded.config.include,
          excludeGlobs: loaded.config.exclude,
        );
        for (final p in pkgs) {
          final kind = p.kind.name;
          out.writeln('- ${p.name.value} → ${p.path} ($kind)');
        }
      } else {
        for (final p in projects) {
          out.writeln('- ${p.name} → ${p.path} (${p.kind})');
        }
      }
      return 0;
    }
    if (what == 'groups') {
      final store = (groupStoreFactory ?? (String monocfgPath) {
        final groupsPath = const DefaultPathService().join([monocfgPath, 'groups']);
        final folder = FileListConfigFolder(
          basePath: groupsPath,
          namePolicy: const DefaultSlugNamePolicy(),
        );
        return FileGroupStore(folder);
      })(loaded.monocfgPath);
      final names = await store.listGroups();
      for (final name in names) {
        final members = await store.readGroup(name);
        out.writeln('- $name → ${members.join(', ')}');
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
      final extra = await readMonocfgTasks(loaded.monocfgPath);
      merged.addAll(extra);
      for (final e in merged.entries) {
        final plugin = (e.value['plugin'] ?? 'exec').toString();
        out.writeln('- ${e.key} (plugin: $plugin)');
      }
      return 0;
    }
    err.writeln('Unknown list target: $what');
    return 1;
  }
}
