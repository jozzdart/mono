import 'dart:io';

import 'package:mono_core/mono_core.dart';

class ScanCommand extends Command {
  const ScanCommand();

  @override
  String get name => 'scan';

  @override
  String get description => 'Scan workspace and cache packages';

  @override
  Future<int> run(
    CliContext context,
  ) =>
      runCommand(
        logger: context.logger,
        workspaceConfig: context.workspaceConfig,
        packageScanner: context.packageScanner,
      );

  static Future<int> runCommand({
    required Logger logger,
    required WorkspaceConfig workspaceConfig,
    required PackageScanner packageScanner,
  }) async {
    final root = Directory.current.path;
    final loaded = await workspaceConfig.loadRootConfig();
    await workspaceConfig.ensureMonocfgScaffold(loaded.monocfgPath);
    final pkgs = await packageScanner.scan(
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
    logger.log(
        'Detected ${records.length} packages and wrote projects to mono.yaml');
    return 0;
  }
}
