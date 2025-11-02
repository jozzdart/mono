import 'package:test/test.dart';
import 'package:mono_core/src/types/types.dart';

PackageName pkg(String v) => PackageName(v);
GroupName grp(String v) => GroupName(v);
CommandId cmd(String v) => CommandId(v);
PluginId plug(String v) => PluginId(v);

void main() {
  group('PackageKind', () {
    test('contains dart and flutter', () {
      expect(PackageKind.values.length, 2);
      expect(PackageKind.values,
          containsAll([PackageKind.dart, PackageKind.flutter]));
    });
  });

  group('Value objects', () {
    test('PackageName equality/hashCode/toString', () {
      expect(pkg('a'), equals(pkg('a')));
      expect(pkg('a'), isNot(equals(pkg('b'))));
      expect(pkg('a').hashCode, equals(pkg('a').hashCode));
      expect(pkg('a').toString(), 'a');
    });

    test('GroupName equality/hashCode/toString', () {
      expect(grp('g'), equals(grp('g')));
      expect(grp('g'), isNot(equals(grp('h'))));
      expect(grp('g').hashCode, equals(grp('g').hashCode));
      expect(grp('g').toString(), 'g');
    });

    test('CommandId equality/hashCode/toString', () {
      expect(cmd('c'), equals(cmd('c')));
      expect(cmd('c'), isNot(equals(cmd('d'))));
      expect(cmd('c').hashCode, equals(cmd('c').hashCode));
      expect(cmd('c').toString(), 'c');
    });

    test('PluginId equality/hashCode/toString', () {
      expect(plug('p'), equals(plug('p')));
      expect(plug('p'), isNot(equals(plug('q'))));
      expect(plug('p').hashCode, equals(plug('p').hashCode));
      expect(plug('p').toString(), 'p');
    });
  });

  group('MonoPackage', () {
    test('equality uses set equality and ignores set order', () {
      final p1 = MonoPackage(
        name: pkg('app'),
        path: '/app',
        kind: PackageKind.dart,
        localDependencies: {pkg('a'), pkg('b')},
        tags: {'x', 'y'},
      );
      final p2 = MonoPackage(
        name: pkg('app'),
        path: '/app',
        kind: PackageKind.dart,
        localDependencies: {pkg('b'), pkg('a')},
        tags: {'y', 'x'},
      );
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });

    test('inequality when any field differs', () {
      final base = MonoPackage(
        name: pkg('app'),
        path: '/app',
        kind: PackageKind.dart,
        localDependencies: {pkg('a')},
        tags: {'x'},
      );
      expect(
        base,
        isNot(
          equals(MonoPackage(
            name: pkg('APP'),
            path: '/app',
            kind: PackageKind.dart,
            localDependencies: {pkg('a')},
            tags: {'x'},
          )),
        ),
      );
      expect(
        base,
        isNot(
          equals(MonoPackage(
            name: pkg('app'),
            path: '/other',
            kind: PackageKind.dart,
            localDependencies: {pkg('a')},
            tags: {'x'},
          )),
        ),
      );
      expect(
        base,
        isNot(
          equals(MonoPackage(
            name: pkg('app'),
            path: '/app',
            kind: PackageKind.flutter,
            localDependencies: {pkg('a')},
            tags: {'x'},
          )),
        ),
      );
      expect(
        base,
        isNot(
          equals(MonoPackage(
            name: pkg('app'),
            path: '/app',
            kind: PackageKind.dart,
            localDependencies: {pkg('b')},
            tags: {'x'},
          )),
        ),
      );
      expect(
        base,
        isNot(
          equals(MonoPackage(
            name: pkg('app'),
            path: '/app',
            kind: PackageKind.dart,
            localDependencies: {pkg('a')},
            tags: {'y'},
          )),
        ),
      );
    });

    test('copyWith updates fields and produces unmodifiable sets', () {
      final original = MonoPackage(
        name: pkg('app'),
        path: '/app',
        kind: PackageKind.dart,
        localDependencies: {pkg('a'), pkg('b')},
        tags: {'x', 'y'},
      );
      final updated = original.copyWith(
        path: '/new',
        kind: PackageKind.flutter,
        localDependencies: {pkg('a')},
        tags: {'x'},
      );

      expect(updated.name, original.name);
      expect(updated.path, '/new');
      expect(updated.kind, PackageKind.flutter);
      expect(updated.localDependencies, {pkg('a')});
      expect(updated.tags, {'x'});

      expect(
        () => updated.localDependencies.add(pkg('z')),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => updated.tags.add('z'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('MonoRepository', () {
    test('findPackageByName returns package or null', () {
      final a = MonoPackage(name: pkg('a'), path: '/a', kind: PackageKind.dart);
      final b =
          MonoPackage(name: pkg('b'), path: '/b', kind: PackageKind.flutter);
      final repo = MonoRepository(rootPath: '/root', packages: [a, b]);

      expect(repo.findPackageByName(pkg('a')), same(a));
      expect(repo.findPackageByName(pkg('b')), same(b));
      expect(repo.findPackageByName(pkg('c')), isNull);
    });

    test('equality uses rootPath and order-sensitive package list', () {
      final a1 =
          MonoPackage(name: pkg('a'), path: '/a', kind: PackageKind.dart);
      final b1 =
          MonoPackage(name: pkg('b'), path: '/b', kind: PackageKind.flutter);
      final r1 = MonoRepository(rootPath: '/root', packages: [a1, b1]);
      final r2 = MonoRepository(rootPath: '/root', packages: [a1, b1]);
      final r3 = MonoRepository(rootPath: '/root', packages: [b1, a1]);
      final r4 = MonoRepository(rootPath: '/other', packages: [a1, b1]);

      expect(r1, equals(r2));
      expect(r1, isNot(equals(r3))); // order matters
      expect(r1, isNot(equals(r4))); // rootPath matters
    });
  });

  group('PackageGroup', () {
    test('equality and hashCode based on name and set-equal members', () {
      final g1 = PackageGroup(name: grp('g'), members: {pkg('a'), pkg('b')});
      final g2 = PackageGroup(name: grp('g'), members: {pkg('b'), pkg('a')});
      final g3 = PackageGroup(name: grp('g'), members: {pkg('a')});
      final g4 = PackageGroup(name: grp('h'), members: {pkg('a'), pkg('b')});

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
      expect(g1, isNot(equals(g3)));
      expect(g1, isNot(equals(g4)));
    });
  });

  group('TaskSpec', () {
    test('equality across id, optional plugin, and set-equal dependsOn', () {
      final t1 = TaskSpec(
        id: cmd('build'),
        plugin: plug('p'),
        dependsOn: {cmd('a'), cmd('b')},
      );
      final t2 = TaskSpec(
        id: cmd('build'),
        plugin: plug('p'),
        dependsOn: {cmd('b'), cmd('a')},
      );
      final t3 = TaskSpec(
        id: cmd('build'),
        plugin: plug('q'),
        dependsOn: {cmd('a'), cmd('b')},
      );
      final t4 = TaskSpec(
        id: cmd('test'),
        plugin: plug('p'),
        dependsOn: {cmd('a'), cmd('b')},
      );

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1, isNot(equals(t3)));
      expect(t1, isNot(equals(t4)));
    });
  });
}
