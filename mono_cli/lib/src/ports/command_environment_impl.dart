import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

/// Default implementation building a CommandEnvironment from files and CLI opts.
class DefaultCommandEnvironmentBuilder implements CommandEnvironmentBuilder {
  const DefaultCommandEnvironmentBuilder();

  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore Function(String monocfgPath) groupStoreFactory,
  }) async {
    // Load mono.yaml
    final rawYaml = await _readFileIfExists('mono.yaml');
    final loader = const YamlConfigLoader();
    final config = loader.load(rawYaml);
    final monocfgPath = _extractMonocfgPath(rawYaml);

    // Scan packages
    final root = Directory.current.path;
    final scanner = const FileSystemPackageScanner();
    final packages = await scanner.scan(
      rootPath: root,
      includeGlobs: config.include,
      excludeGlobs: config.exclude,
    );

    // Build graph
    final graph = const DefaultGraphBuilder().build(packages);

    // Load groups
    final store = groupStoreFactory(monocfgPath);
    final groups = <String, Set<String>>{};
    final names = await store.listGroups();
    for (final name in names) {
      final members = await store.readGroup(name);
      groups[name] = members.toSet();
    }

    // Selector and effective options
    final selector = const DefaultTargetSelector();
    final effectiveOrder = _effectiveOrder(inv, config) == 'dependency';
    final effectiveConcurrency = _effectiveConcurrency(inv, config);

    return CommandEnvironment(
      config: config,
      monocfgPath: monocfgPath,
      packages: packages,
      graph: graph,
      groups: groups,
      selector: selector,
      effectiveOrder: effectiveOrder,
      effectiveConcurrency: effectiveConcurrency,
    );
  }
}

Future<String> _readFileIfExists(String path) async {
  final f = File(path);
  if (await f.exists()) return f.readAsString();
  return '';
}

String _extractMonocfgPath(String rawYaml) {
  if (rawYaml.trim().isEmpty) return 'monocfg';
  final node = loadYaml(rawYaml, recover: true);
  if (node is! YamlMap) return 'monocfg';
  final settings = node['settings'];
  if (settings is YamlMap) {
    final v = settings['monocfgPath'];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return 'monocfg';
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
