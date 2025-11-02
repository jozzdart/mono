import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import '../config_io.dart';

class TasksCommand {
  static Future<int> run({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
  }) async {
    final loaded = await loadRootConfig();
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
}
