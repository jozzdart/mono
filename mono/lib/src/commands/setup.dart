import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import '../config_io.dart';

class SetupCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required IOSink out,
      required IOSink err}) async {
    await writeRootConfigIfMissing();
    final loaded = await loadRootConfig();
    await ensureMonocfgScaffold(loaded.monocfgPath);
    out.writeln(
        'Created/verified mono.yaml and ${loaded.monocfgPath}/ scaffolding');
    return 0;
  }
}
