import 'dart:io';

import 'package:mono/src/commands/scan.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

import '../util/fs_fixtures.dart';
import '../util/fakes.dart';

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

  group('ScanCommand', () {
    test('writes empty projects map in mono.yaml when no packages', () async {
      final ws = await createTempWorkspace('mono_scan_');
      ws.enter();
      try {
        await writeMonoYaml();

        final outB = StringBuffer();
        final errB = StringBuffer();
        final code = await ScanCommand.runCommand(
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
        );
        expect(code, 0);

        final projects = await workspaceConfig.readMonocfgProjects('monocfg');
        expect(projects, isEmpty);
        expect(outB.toString(), contains('Detected 0 packages'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('detects multiple packages and writes records', () async {
      final ws = await createTempWorkspace('mono_scan_');
      ws.enter();
      try {
        await writeMonoYaml();
        // Create two packages: a (dart), nested/b (flutter)
        final aDir = p.join(Directory.current.path, 'a');
        final bDir = p.join(Directory.current.path, 'nested', 'b');
        writePubspec(aDir, 'a');
        writePubspec(bDir, 'b', flutter: true);

        final outB = StringBuffer();
        final errB = StringBuffer();
        final code = await ScanCommand.runCommand(
          logger: BufferingLogger(outB, errB),
          workspaceConfig: workspaceConfig,
          packageScanner: const FileSystemPackageScanner(),
        );
        expect(code, 0);

        final list = await workspaceConfig.readMonocfgProjects('monocfg');
        expect(list.length, 2);
        expect(list.map((e) => e.name), containsAll(['a', 'b']));
        expect(outB.toString(), contains('Detected 2 packages'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
