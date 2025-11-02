import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('MonoPackage', () {
    test('equality and copyWith', () {
      final a = MonoPackage(
        name: PackageName('a'),
        path: 'packages/a',
        kind: PackageKind.dart,
      );
      final b = a.copyWith(path: 'packages/a');
      expect(a, equals(b));

      final c = a.copyWith(kind: PackageKind.flutter);
      expect(c.kind, PackageKind.flutter);
      expect(c.name, a.name);
      expect(c == a, isFalse);
    });
  });

  group('MonoRepository', () {
    test('findPackageByName', () {
      final p1 = MonoPackage(
          name: PackageName('p1'), path: 'p1', kind: PackageKind.dart);
      final repo = MonoRepository(rootPath: '.', packages: [p1]);
      expect(repo.findPackageByName(PackageName('p1')), p1);
      expect(repo.findPackageByName(PackageName('x')), isNull);
    });
  });
}
