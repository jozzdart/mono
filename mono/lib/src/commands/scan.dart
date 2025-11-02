import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

class ScanCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required IOSink out,
      required IOSink err,
      required WorkspaceConfig workspaceConfig}) async {
    final root = Directory.current.path;
    final loaded = await workspaceConfig.loadRootConfig();
    await workspaceConfig.ensureMonocfgScaffold(loaded.monocfgPath);
    final scanner = const FileSystemPackageScanner();
    final pkgs = await scanner.scan(
      rootPath: root,
      includeGlobs: loaded.config.include,
      excludeGlobs: loaded.config.exclude,
    );
    final records = [
      for (final p in pkgs)
        PackageRecord(
          name: p.name.value,
          path: p.path,
          kind: p.kind == PackageKind.flutter ? 'flutter' : 'dart',
        )
    ];
    await workspaceConfig.writeMonocfgProjects(loaded.monocfgPath, records);
    out.writeln(
        'Detected ${records.length} packages and wrote ${loaded.monocfgPath}/mono_projects.yaml');
    return 0;
  }
}
