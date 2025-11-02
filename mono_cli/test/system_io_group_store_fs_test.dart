import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FileGroupStore', () {
    late Directory tmp;
    late FileGroupStore groups;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('mono_cli_group_store_');
      final folder = FileListConfigFolder(basePath: p.join(tmp.path, 'groups'));
      groups = FileGroupStore(folder);
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('CRUD and listing', () async {
      expect(await groups.listGroups(), isEmpty);
      expect(await groups.exists('ui'), isFalse);

      await groups.writeGroup('ui', ['app', 'core']);
      expect(await groups.exists('ui'), isTrue);
      expect(await groups.listGroups(), ['ui']);

      final items = await groups.readGroup('ui');
      expect(items, ['app', 'core']);

      await groups.writeGroup('tools', ['lint']);
      expect(await groups.listGroups(), ['tools', 'ui']);

      await groups.deleteGroup('ui');
      expect(await groups.exists('ui'), isFalse);
    });
  });
}
