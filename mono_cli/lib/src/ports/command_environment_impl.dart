import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

/// Default implementation building a CommandEnvironment from files and CLI opts.
class DefaultCommandEnvironmentBuilder implements CommandEnvironmentBuilder {
  final WorkspaceConfig workspaceConfig;
  final PackageScanner packageScanner;
  final GraphBuilder graphBuilder;
  final TargetSelector targetSelector;

  const DefaultCommandEnvironmentBuilder({
    this.workspaceConfig = const FileWorkspaceConfig(),
    this.packageScanner = const FileSystemPackageScanner(),
    this.graphBuilder = const DefaultGraphBuilder(),
    this.targetSelector = const DefaultTargetSelector(),
  });

  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore groupStore,
  }) async {
    // Load configuration and resolve monocfg path via injected workspace config
    final loaded = await workspaceConfig.loadRootConfig();
    final config = loaded.config;
    final monocfgPath = loaded.monocfgPath;

    // Scan packages
    final root = Directory.current.path;
    final packages = await packageScanner.scan(
      rootPath: root,
      includeGlobs: config.include,
      excludeGlobs: config.exclude,
    );

    // Build graph
    final graph = graphBuilder.build(packages);

    // Load groups

    final store = groupStore;
    final groups = <String, Set<String>>{};
    final names = await store.listGroups();
    for (final name in names) {
      final members = await store.readGroup(name);
      groups[name] = members.toSet();
    }

    // Effective options
    final effectiveOrder = _effectiveOrder(inv, config) == 'dependency';
    final effectiveConcurrency = _effectiveConcurrency(inv, config);

    return CommandEnvironment(
      config: config,
      monocfgPath: monocfgPath,
      packages: packages,
      graph: graph,
      groups: groups,
      selector: targetSelector,
      effectiveOrder: effectiveOrder,
      effectiveConcurrency: effectiveConcurrency,
    );
  }
}

String _effectiveOrder(CliInvocation inv, MonoConfig cfg) {
  final list = inv.options['order'];
  final fromCli = (list != null && list.isNotEmpty) ? list.first : null;
  return fromCli ?? cfg.settings.defaultOrder;
}

int _effectiveConcurrency(CliInvocation inv, MonoConfig cfg) {
  final list = inv.options['concurrency'];
  final fromCli = (list != null && list.isNotEmpty) ? list.first : null;
  final str = fromCli ?? cfg.settings.concurrency;
  final n = int.tryParse(str);
  if (n != null && n > 0) return n;
  try {
    return Platform.numberOfProcessors.clamp(1, 8);
  } catch (_) {
    return 4;
  }
}
