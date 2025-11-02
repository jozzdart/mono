import 'package:mono/src/models.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('PackageRecord', () {
    test('constructor sets fields', () {
      const p = PackageRecord(name: 'a', path: 'packages/a', kind: 'dart');
      expect(p.name, 'a');
      expect(p.path, 'packages/a');
      expect(p.kind, 'dart');
    });

    test('fromMono maps kinds correctly', () {
      final dartPkg = MonoPackage(
        name: const PackageName('x'),
        path: 'packages/x',
        kind: PackageKind.dart,
      );
      final flutterPkg = MonoPackage(
        name: const PackageName('y'),
        path: 'packages/y',
        kind: PackageKind.flutter,
      );

      final r1 = PackageRecord.fromMono(dartPkg);
      final r2 = PackageRecord.fromMono(flutterPkg);

      expect(r1.name, 'x');
      expect(r1.path, 'packages/x');
      expect(r1.kind, 'dart');
      expect(r2.name, 'y');
      expect(r2.path, 'packages/y');
      expect(r2.kind, 'flutter');
    });
  });
}


