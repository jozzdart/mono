import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

void main() {
  test('src.dart re-exports key symbols', () async {
    final workspaceConfig = const FileWorkspaceConfig();
    // Able to construct PackageRecord and call a config IO function
    const rec = PackageRecord(name: 'n', path: 'p', kind: 'dart');
    expect(rec.name, 'n');

    final tmp = await Directory.systemTemp.createTemp('mono_src_exports_');
    addTearDown(() async => tmp.delete(recursive: true));

    final missing = '${tmp.path}/definitely_missing.txt';
    final prev = Directory.current.path;
    Directory.current = tmp.path;
    addTearDown(() => Directory.current = prev);
    final contents = await workspaceConfig.readMonocfgProjects(missing);
    expect(contents, isEmpty);
  });
}
