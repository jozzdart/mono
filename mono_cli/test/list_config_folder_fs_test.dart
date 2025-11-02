import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  test('DefaultSlugNamePolicy normalizes names', () {
    const policy = DefaultSlugNamePolicy();
    expect(policy.normalize('UI Group'), 'ui-group');
    expect(policy.normalize('core_utils'), 'core-utils');
    expect(policy.normalize('  A..B  '), 'a-b');
    expect(policy.isValid('ui-group'), isTrue);
  });

  test('FileListConfigFolder read/write/list/delete', () async {
    final tmp = await Directory.systemTemp.createTemp('mono_cli_list_store_');
    try {
      final base = Directory('${tmp.path}/cfg/groups');
      final store = FileListConfigFolder(basePath: base.path);
      // initial empty
      expect(await store.listNames(), isEmpty);
      expect(await store.exists('ui'), isFalse);

      // write with comments/blank lines
      await store.writeList('ui', ['app', '', '# comment', 'core']);
      expect(await store.exists('ui'), isTrue);
      expect(await store.listNames(), contains('ui'));
      final items = await store.readList('ui');
      expect(items, containsAll(['app', 'core']));

      // another group
      await store.writeList('tools', ['lint']);
      final names = await store.listNames();
      expect(names, containsAll(['ui', 'tools']));

      // delete
      await store.delete('ui');
      expect(await store.exists('ui'), isFalse);
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}


