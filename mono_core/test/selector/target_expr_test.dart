import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('TargetExpr construction', () {
    test('TargetAll is a TargetExpr and const-constructible', () {
      const all = TargetAll();
      expect(all, isA<TargetExpr>());
    });

    test('TargetPackage stores name', () {
      const pkg = TargetPackage('core');
      expect(pkg, isA<TargetExpr>());
      expect(pkg.name, 'core');
    });

    test('TargetGroup stores groupName', () {
      const grp = TargetGroup('apps');
      expect(grp, isA<TargetExpr>());
      expect(grp.groupName, 'apps');
    });

    test('TargetGlob stores pattern', () {
      const glob = TargetGlob('app_*');
      expect(glob, isA<TargetExpr>());
      expect(glob.pattern, 'app_*');
    });
  });

  group('Const canonicalization and identity semantics', () {
    test('Identical for equal consts', () {
      expect(identical(const TargetAll(), const TargetAll()), isTrue);
      expect(identical(const TargetPackage('x'), const TargetPackage('x')),
          isTrue);
      expect(identical(const TargetGroup('g'), const TargetGroup('g')), isTrue);
      expect(identical(const TargetGlob('p'), const TargetGlob('p')), isTrue);
    });

    test('Non-const instances are distinct even with same data', () {
      final a = TargetPackage('x');
      final b = TargetPackage('x');
      expect(identical(a, b), isFalse);

      final g1 = TargetGroup('g');
      final g2 = TargetGroup('g');
      expect(identical(g1, g2), isFalse);

      final gl1 = TargetGlob('p');
      final gl2 = TargetGlob('p');
      expect(identical(gl1, gl2), isFalse);
    });

    test('Const vs non-const are not identical', () {
      const c = TargetPackage('x');
      final n = TargetPackage('x');
      expect(identical(c, n), isFalse);
    });
  });

  group('Pattern matching over sealed TargetExpr', () {
    String describe(TargetExpr expr) {
      return switch (expr) {
        TargetAll() => 'all',
        TargetPackage(:final name) => 'package:$name',
        TargetGroup(:final groupName) => 'group:$groupName',
        TargetGlob(:final pattern) => 'glob:$pattern',
      };
    }

    test('Switch expression is exhaustive and returns expected descriptions',
        () {
      expect(describe(const TargetAll()), 'all');
      expect(describe(const TargetPackage('core')), 'package:core');
      expect(describe(const TargetGroup('apps')), 'group:apps');
      expect(describe(const TargetGlob('app_*')), 'glob:app_*');
    });
  });

  group('Collections behavior (identity-based equality)', () {
    test('Set deduplicates identical consts', () {
      const a1 = TargetAll();
      const a2 = TargetAll();
      const p1 = TargetPackage('x');
      const p2 = TargetPackage('x');

      final set = <TargetExpr>{}
        ..add(a1)
        ..add(a2)
        ..add(p1)
        ..add(p2);
      expect(set.length, 2);
      expect(set.contains(a1), isTrue);
      expect(set.contains(p1), isTrue);
    });

    test('Set keeps distinct non-const instances with same data', () {
      final p1 = TargetPackage('x');
      final p2 = TargetPackage('x');
      final set = {p1, p2};
      expect(set.length, 2);
      expect(identical(p1, p2), isFalse);
    });

    test('Map keys with const canonicalization', () {
      const k1 = TargetGroup('g');
      const k2 = TargetGroup('g');
      final map = {k1: 1};
      map[k2] = 2; // same const key instance due to canonicalization
      expect(map.length, 1);
      expect(map[k1], 2);
    });

    test('Map treats non-const equal-data keys as distinct', () {
      final k1 = TargetGlob('p');
      final k2 = TargetGlob('p');
      final map = {k1: 1};
      map[k2] = 2; // distinct identity
      expect(map.length, 2);
      expect(map[k1], 1);
      expect(map[k2], 2);
    });
  });
}
