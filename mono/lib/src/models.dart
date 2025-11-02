import 'package:mono_cli/mono_cli.dart';

class PackageRecord {
  const PackageRecord(
      {required this.name, required this.path, required this.kind});
  final String name;
  final String path;
  final String kind; // 'dart' | 'flutter'

  factory PackageRecord.fromMono(MonoPackage p) => PackageRecord(
        name: p.name.value,
        path: p.path,
        kind: p.kind == PackageKind.flutter ? 'flutter' : 'dart',
      );
}
