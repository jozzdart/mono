import 'dart:io';

import 'package:mono_cli_shared_contracts/mono_cli_shared_contracts.dart';
import 'package:mono_scanner_fs/mono_scanner_fs.dart';

import '../config_io.dart';
import '../models.dart';

class ScanCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required IOSink out,
      required IOSink err}) async {
    final root = Directory.current.path;
    final loaded = await loadRootConfig();
    await ensureMonocfgScaffold(loaded.monocfgPath);
    final scanner = const FileSystemPackageScanner();
    final pkgs = await scanner.scan(
      rootPath: root,
      includeGlobs: loaded.config.include,
      excludeGlobs: loaded.config.exclude,
    );
    final records = [for (final p in pkgs) PackageRecord.fromMono(p)];
    await writeMonocfgProjects(loaded.monocfgPath, records);
    out.writeln(
        'Detected ${records.length} packages and wrote ${loaded.monocfgPath}/mono_projects.yaml');
    return 0;
  }
}
