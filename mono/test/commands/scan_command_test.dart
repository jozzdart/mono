import 'dart:io';

import 'package:mono/src/commands/scan.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../util/fs_fixtures.dart';

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

  group('ScanCommand', () {
    test('writes empty projects file when no packages', () async {
      final ws = await createTempWorkspace('mono_scan_');
      ws.enter();
      try {
        await writeMonoYaml();

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['scan']);
        final code = await ScanCommand.run(
            inv: inv,
            out: outCap.sink,
            err: errCap.sink,
            workspaceConfig: workspaceConfig);
        expect(code, 0);

        final proj = File(p.join('monocfg', 'mono_projects.yaml'));
        expect(proj.existsSync(), isTrue);
        final contents = await proj.readAsString();
        expect(contents.trim(), startsWith('packages:'));
        expect(outCap.text, contains('Detected 0 packages'));
        expect(errCap.text.trim(), isEmpty);
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

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['scan']);
        final code = await ScanCommand.run(
            inv: inv,
            out: outCap.sink,
            err: errCap.sink,
            workspaceConfig: workspaceConfig);
        expect(code, 0);

        final proj = File(p.join('monocfg', 'mono_projects.yaml'));
        expect(proj.existsSync(), isTrue);
        final contents = await proj.readAsString();
        expect(contents, contains('name: a'));
        expect(contents, contains('name: b'));
        expect(outCap.text, contains('Detected 2 packages'));
        expect(errCap.text.trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
