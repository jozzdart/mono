import 'dart:io';

import 'package:mono/src/src.dart';
import 'package:test/test.dart';

void main() {
  test('src.dart re-exports key symbols', () async {
    // Able to construct PackageRecord and call a config IO function
    const rec = PackageRecord(name: 'n', path: 'p', kind: 'dart');
    expect(rec.name, 'n');

    final tmp = await Directory.systemTemp.createTemp('mono_src_exports_');
    addTearDown(() async => tmp.delete(recursive: true));

    final missing = '${tmp.path}/definitely_missing.txt';
    final contents = await readFileIfExists(missing);
    expect(contents, '');
  });
}
