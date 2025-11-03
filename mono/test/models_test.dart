import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

void main() {
  group('PackageRecord', () {
    test('constructor sets fields', () {
      const p = PackageRecord(name: 'a', path: 'packages/a', kind: 'dart');
      expect(p.name, 'a');
      expect(p.path, 'packages/a');
      expect(p.kind, 'dart');
    });

    // mapping from MonoPackage to PackageRecord is now done at call sites.
  });
}
