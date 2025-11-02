import 'dart:io';

import 'package:mono_core/mono_core.dart';

/// High-level executor for running a TaskSpec across selected targets.
///
/// This centralizes the common flow used by multiple commands:
///   build environment → resolve targets → plan → dry-run/execute.
@immutable
abstract class TaskExecutor {
  const TaskExecutor();

  Future<int> execute({
    required TaskSpec task,
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    Map<String, String> env,
    String? dryRunLabel,
  });
}
