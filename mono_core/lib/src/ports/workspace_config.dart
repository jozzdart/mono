import 'package:mono_core/mono_core.dart';

@immutable
class LoadedRootConfig {
  const LoadedRootConfig({
    required this.config,
    required this.monocfgPath,
    required this.rawYaml,
  });
  final MonoConfig config;
  final String monocfgPath;
  final String rawYaml;
}

@immutable
class PackageRecord {
  const PackageRecord({
    required this.name,
    required this.path,
    required this.kind,
  });
  final String name; // package name
  final String path; // relative path from workspace root
  final String kind; // 'dart' | 'flutter'
}

@immutable
abstract class WorkspaceConfig {
  const WorkspaceConfig();

  Future<LoadedRootConfig> loadRootConfig({String path = 'mono.yaml'});

  Future<void> writeRootConfigIfMissing({String path = 'mono.yaml'});

  Future<void> ensureMonocfgScaffold(String monocfgPath);

  Future<List<PackageRecord>> readMonocfgProjects(String monocfgPath);

  Future<void> writeMonocfgProjects(
      String monocfgPath, List<PackageRecord> packages);

  Future<Map<String, Map<String, Object?>>> readMonocfgTasks(
      String monocfgPath);

  Future<void> writeRootConfigGroups(
      String path, Map<String, List<String>> groups);
}
