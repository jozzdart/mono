import 'dart:io';

import 'package:meta/meta.dart';
import 'package:mono_config_contracts/mono_config_contracts.dart';
import 'package:mono_config_yaml/mono_config_yaml.dart';
import 'package:yaml/yaml.dart';

import 'models.dart';

@immutable
class LoadedRootConfig {
  const LoadedRootConfig({required this.config, required this.monocfgPath, required this.rawYaml});
  final MonoConfig config;
  final String monocfgPath;
  final String rawYaml;
}

Future<String> readFileIfExists(String path) async {
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

Future<LoadedRootConfig> loadRootConfig({String path = 'mono.yaml'}) async {
  final raw = await readFileIfExists(path);
  final loader = const YamlConfigLoader();
  final config = loader.load(raw);
  final monocfgPath = _extractMonocfgPath(raw);
  return LoadedRootConfig(config: config, monocfgPath: monocfgPath, rawYaml: raw);
}

Future<void> writeRootConfigIfMissing({String path = 'mono.yaml'}) async {
  final f = File(path);
  if (await f.exists()) return;
  final content = '''# mono configuration
settings:
  monocfgPath: monocfg
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
''';
  await f.writeAsString(content);
}

Future<void> ensureMonocfgScaffold(String monocfgPath) async {
  final dir = Directory(monocfgPath);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final projects = File('$monocfgPath/mono_projects.yaml');
  if (!await projects.exists()) {
    await projects.writeAsString('packages: []\n');
  }
  final tasks = File('$monocfgPath/tasks.yaml');
  if (!await tasks.exists()) {
    await tasks.writeAsString('# tasks:\n');
  }
}

Future<List<PackageRecord>> readMonocfgProjects(String monocfgPath) async {
  final f = File('$monocfgPath/mono_projects.yaml');
  if (!await f.exists()) return const <PackageRecord>[];
  final raw = await f.readAsString();
  final y = loadYaml(raw, recover: true);
  if (y is! YamlMap) return const <PackageRecord>[];
  final list = y['packages'];
  if (list is! YamlList) return const <PackageRecord>[];
  final out = <PackageRecord>[];
  for (final node in list.nodes) {
    final m = node.value;
    if (m is! YamlMap) continue;
    final name = m['name']?.toString() ?? '';
    final path = m['path']?.toString() ?? '';
    final kind = m['kind']?.toString() ?? 'dart';
    if (name.isEmpty || path.isEmpty) continue;
    out.add(PackageRecord(name: name, path: path, kind: kind));
  }
  return out;
}

Future<void> writeMonocfgProjects(String monocfgPath, List<PackageRecord> packages) async {
  final sb = StringBuffer();
  sb.writeln('packages:');
  for (final p in packages) {
    sb.writeln('  - name: ${p.name}');
    sb.writeln('    path: ${p.path}');
    sb.writeln('    kind: ${p.kind}');
  }
  final f = File('$monocfgPath/mono_projects.yaml');
  await f.writeAsString(sb.toString());
}

Future<Map<String, Map<String, Object?>>> readMonocfgTasks(String monocfgPath) async {
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
        for (final ve in val.nodes.entries) ve.key.value.toString(): ve.value.value,
      };
    }
  }
  return out;
}


