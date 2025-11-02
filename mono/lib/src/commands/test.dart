import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

@immutable
class TestCommand {
  static Future<int> run({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    required TaskExecutor executor,
  }) async {
    final task = TaskSpec(
      id: const CommandId('test'),
      plugin: const PluginId('test'),
    );
    return executor.execute(
      task: task,
      inv: inv,
      out: out,
      err: err,
      groupStoreFactory: groupStoreFactory,
      envBuilder: envBuilder,
      plugins: plugins,
    );
  }
}
