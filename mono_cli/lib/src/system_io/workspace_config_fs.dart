import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class FileWorkspaceConfig implements WorkspaceConfig {
  const FileWorkspaceConfig();

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

  @override
  Future<LoadedRootConfig> loadRootConfig({String path = 'mono.yaml'}) async {
    final raw = await _readFileIfExists(path);
    final loader = const YamlConfigLoader();
    final config = loader.load(raw);
    final monocfgPath = _extractMonocfgPath(raw);
    return LoadedRootConfig(
      config: config,
      monocfgPath: monocfgPath,
      rawYaml: raw,
    );
  }

  @override
  Future<void> writeRootConfigIfMissing({String path = 'mono.yaml'}) async {
    final f = File(path);
    if (await f.exists()) return;
    final yaml = toYaml(defaultConfig(), monocfgPath: 'monocfg');
    await f.writeAsString(yaml);
  }

  @override
  Future<void> ensureMonocfgScaffold(String monocfgPath) async {
    final dir = Directory(monocfgPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final groupsDir = Directory('$monocfgPath/groups');
    if (!await groupsDir.exists()) {
      await groupsDir.create(recursive: true);
    }
    final tasks = File('$monocfgPath/tasks.yaml');
    if (!await tasks.exists()) {
      await tasks.writeAsString('# tasks:\n');
    }
  }

  @override
  Future<List<PackageRecord>> readMonocfgProjects(String monocfgPath) async {
    // Projects are now stored in the root mono.yaml under
    // 'dart_projects:' and 'flutter_projects:' maps.
    final loaded = await loadRootConfig();
    final raw = loaded.rawYaml;
    if (raw.trim().isEmpty) return const <PackageRecord>[];
    final y = loadYaml(raw, recover: true);
    if (y is! YamlMap) return const <PackageRecord>[];
    final out = <PackageRecord>[];
    final dartMap = y['dart_projects'];
    if (dartMap is YamlMap) {
      for (final e in dartMap.nodes.entries) {
        final name = e.key.value.toString();
        final path = e.value.value.toString();
        if (name.isEmpty || path.isEmpty) continue;
        out.add(PackageRecord(name: name, path: path, kind: 'dart'));
      }
    }
    final flutterMap = y['flutter_projects'];
    if (flutterMap is YamlMap) {
      for (final e in flutterMap.nodes.entries) {
        final name = e.key.value.toString();
        final path = e.value.value.toString();
        if (name.isEmpty || path.isEmpty) continue;
        out.add(PackageRecord(name: name, path: path, kind: 'flutter'));
      }
    }
    return out;
  }

  @override
  Future<void> writeMonocfgProjects(
    String monocfgPath,
    List<PackageRecord> packages,
  ) async {
    // Build updated config with separated dart/flutter maps and write via toYaml.
    final loaded = await loadRootConfig();
    final cfg = loaded.config;
    final dartMap = <String, String>{
      for (final e in cfg.dartProjects.entries) e.key: e.value,
    };
    final flutterMap = <String, String>{
      for (final e in cfg.flutterProjects.entries) e.key: e.value,
    };
    for (final p in packages) {
      if (p.kind == 'flutter') {
        flutterMap[p.name] = p.path;
        dartMap.remove(p.name);
      } else {
        dartMap[p.name] = p.path;
        flutterMap.remove(p.name);
      }
    }
    final updated = MonoConfig(
      include: cfg.include,
      exclude: cfg.exclude,
      dartProjects: dartMap,
      flutterProjects: flutterMap,
      groups: cfg.groups,
      tasks: cfg.tasks,
      settings: cfg.settings,
      logger: cfg.logger,
    );
    final yaml = toYaml(updated, monocfgPath: loaded.monocfgPath);
    final f = File('mono.yaml');
    await f.writeAsString(yaml);
  }

  @override
  Future<Map<String, Map<String, Object?>>> readMonocfgTasks(
      String monocfgPath) async {
    final f = File('$monocfgPath/tasks.yaml');
    if (!await f.exists()) return const {};
    final raw = await f.readAsString();
    final y = loadYaml(raw, recover: true);
    if (y is! YamlMap) return const {};
    final out = <String, Map<String, Object?>>{};
    for (final e in y.nodes.entries) {
      final key = e.key.value.toString();
      final val = e.value;
      if (val is YamlMap) {
        out[key] = {
          for (final ve in val.nodes.entries)
            ve.key.value.toString(): ve.value.value,
        };
      }
    }
    return out;
  }

  @override
  Future<void> writeRootConfigGroups(
    String path,
    Map<String, List<String>> groups,
  ) async {
    final loaded = await loadRootConfig(path: path);
    final cfg = loaded.config;
    final updated = MonoConfig(
      include: cfg.include,
      exclude: cfg.exclude,
      dartProjects: cfg.dartProjects,
      flutterProjects: cfg.flutterProjects,
      groups: groups,
      tasks: cfg.tasks,
      settings: cfg.settings,
      logger: cfg.logger,
    );
    final yaml = toYaml(updated, monocfgPath: loaded.monocfgPath);
    final f = File(path);
    await f.writeAsString(yaml);
  }

  @override
  Future<void> writeRootConfigNormalized(
      {String path = 'mono.yaml', Logger? logger}) async {
    final loaded = await loadRootConfig(path: path);
    final normalized = normalizeRootConfig(
      loaded.rawYaml,
      monocfgPath: loaded.monocfgPath,
      logger: logger,
    );
    final f = File(path);
    await f.writeAsString(normalized.yaml);
  }
}
