import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FileListConfigFolder', () {
    late Directory tmp;
    late Directory base;
    late FileListConfigFolder store;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mono_cli_list_store_ext_');
      base = Directory(p.join(tmp.path, 'cfg', 'groups'));
      store = FileListConfigFolder(basePath: base.path);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('exists returns false/true appropriately', () async {
      expect(await store.exists('ui'), isFalse);
      await store.writeList('ui', ['app']);
      expect(await store.exists('ui'), isTrue);
    });

    test('listNames returns empty for missing dir and sorts names', () async {
      expect(await store.listNames(), isEmpty);
      await store.writeList('b', ['x']);
      await store.writeList('a', ['y']);
      await store.writeList('c', ['z']);
      expect(await store.listNames(), ['a', 'b', 'c']);
    });

    test('listNames ignores non-.list files and invalid slugs', () async {
      await base.create(recursive: true);
      await File(p.join(base.path, 'ok.list')).writeAsString('one');
      await File(p.join(base.path, 'ignore.txt')).writeAsString('two');
      await File(p.join(base.path, 'BadName.list')).writeAsString('three');
      final names = await store.listNames();
      expect(names, ['ok']);
    });

    test('readList trims, skips blanks and comments', () async {
      await store.writeList('tools', [' lint  ', '', '# comment', 'fmt']);
      final items = await store.readList('tools');
      expect(items, ['lint', 'fmt']);
    });

    test('readList returns empty if file not found', () async {
      expect(await store.readList('nope'), isEmpty);
    });

    test('writeList normalizes name and validates', () async {
      // Normalization from spaces to dash
      await store.writeList('My Tools', ['x']);
      expect(await store.exists('my-tools'), isTrue);
      // Invalid name after normalization throws
      expect(
        () => store.writeList('@@@', ['x']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('writeList creates directory and is atomic-ish (tmp removed)',
        () async {
      await store.writeList('g', ['a', '', 'b']);
      final path = p.join(base.path, 'g.list');
      expect(File(path).existsSync(), isTrue);
      // Ensure only final file remains (no lingering .tmp)
      final files = base
          .listSync()
          .whereType<File>()
          .map((f) => p.basename(f.path))
          .toList();
      expect(files.any((n) => n.endsWith('.tmp')), isFalse);
      // Contents only include non-empty trimmed items
      final lines = await File(path).readAsLines();
      expect(lines, ['a', 'b']);
    });

    test('delete is idempotent', () async {
      await store.writeList('x', ['a']);
      await store.delete('x');
      expect(await store.exists('x'), isFalse);
      // Second delete should not throw
      await store.delete('x');
    });
  });
}
