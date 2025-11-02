import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

enum PackageKind { dart, flutter }

@immutable
class PackageName {
  const PackageName(this.value) : assert(value != '');
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PackageName && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

@immutable
class GroupName {
  const GroupName(this.value) : assert(value != '');
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GroupName && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

@immutable
class MonoPackage {
  const MonoPackage({
    required this.name,
    required this.path,
    required this.kind,
    this.localDependencies = const <PackageName>{},
    this.tags = const <String>{},
  });
  final PackageName name;
  final String path;
  final PackageKind kind;
  final Set<PackageName> localDependencies;
  final Set<String> tags;

  MonoPackage copyWith({
    String? path,
    PackageKind? kind,
    Set<PackageName>? localDependencies,
    Set<String>? tags,
  }) =>
      MonoPackage(
        name: name,
        path: path ?? this.path,
        kind: kind ?? this.kind,
        localDependencies:
            Set.unmodifiable(localDependencies ?? this.localDependencies),
        tags: Set.unmodifiable(tags ?? this.tags),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MonoPackage) return false;
    return name == other.name &&
        path == other.path &&
        kind == other.kind &&
        const SetEquality()
            .equals(localDependencies, other.localDependencies) &&
        const SetEquality().equals(tags, other.tags);
  }

  @override
  int get hashCode => Object.hash(
        name,
        path,
        kind,
        const SetEquality().hash(localDependencies),
        const SetEquality().hash(tags),
      );
}

@immutable
class MonoRepository {
  const MonoRepository({required this.rootPath, required this.packages});
  final String rootPath;
  final List<MonoPackage> packages;
  MonoPackage? findPackageByName(PackageName name) =>
      packages.firstWhereOrNull((p) => p.name == name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonoRepository &&
          rootPath == other.rootPath &&
          const ListEquality().equals(packages, other.packages);
  @override
  int get hashCode =>
      Object.hash(rootPath, const ListEquality().hash(packages));
}

@immutable
class PackageGroup {
  const PackageGroup({required this.name, required this.members});
  final GroupName name;
  final Set<PackageName> members;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackageGroup &&
          name == other.name &&
          const SetEquality().equals(members, other.members);
  @override
  int get hashCode => Object.hash(name, const SetEquality().hash(members));
}

@immutable
class CommandId {
  const CommandId(this.value) : assert(value != '');
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CommandId && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

@immutable
class PluginId {
  const PluginId(this.value) : assert(value != '');
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PluginId && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => value;
}

@immutable
class TaskSpec {
  const TaskSpec({
    required this.id,
    this.plugin,
    this.dependsOn = const <CommandId>{},
  });
  final CommandId id;
  final PluginId? plugin;
  final Set<CommandId> dependsOn;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskSpec &&
          id == other.id &&
          plugin == other.plugin &&
          const SetEquality().equals(dependsOn, other.dependsOn);
  @override
  int get hashCode =>
      Object.hash(id, plugin, const SetEquality().hash(dependsOn));
}
