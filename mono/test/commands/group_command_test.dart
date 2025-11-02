import 'dart:io';

import 'package:mono/src/commands/group.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../util/fakes.dart';
import '../util/fs_fixtures.dart';

void main() {
  group('GroupCommand', () {
    test('usage error when name missing', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['group']);
        final code = await GroupCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          prompter: FakePrompter(),
        );
        expect(code, 2);
        expect(errCap.text, contains('Usage: mono group <group_name>'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('invalid name starting with :', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: [':bad']);
        final code = await GroupCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          prompter: FakePrompter(),
        );
        expect(code, 2);
        expect(errCap.text, contains('Invalid group name: ":bad"'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('existing group and confirm false aborts', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        await ensureMonocfg('monocfg');
        final groupsDir = p.join('monocfg', 'groups');
        await writeFile(p.join(groupsDir, 'dev.list'), 'a\n');

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['dev']);
        final code = await GroupCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          prompter: FakePrompter(nextConfirm: false),
        );
        expect(code, 1);
        expect(errCap.text, contains('Aborted.'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('creates group with selected indices', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        // No cache -> will scan
        writePubspec(p.join(Directory.current.path, 'a'), 'a');
        writePubspec(p.join(Directory.current.path, 'b'), 'b');
        writePubspec(p.join(Directory.current.path, 'c'), 'c');

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['g1']);
        final code = await GroupCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          prompter: FakePrompter(checklistIndices: [0, 2]),
        );
        expect(code, 0);
        expect(outCap.text, contains('Group "g1" saved with 2 member(s).'));
        final f = File(p.join('monocfg', 'groups', 'g1.list'));
        expect(f.existsSync(), isTrue);
        final lines = await f.readAsLines();
        expect(lines, containsAll(<String>['a', 'c']));
        expect(errCap.text.trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('no selections and confirm false => aborts', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'a'), 'a');

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['g2']);
        final code = await GroupCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          prompter: FakePrompter(checklistIndices: [], nextConfirm: false),
        );
        expect(code, 1);
        expect(errCap.text, contains('Aborted.'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });

    test('conflicts with package name', () async {
      final ws = await createTempWorkspace('mono_group_');
      ws.enter();
      try {
        await writeMonoYaml();
        writePubspec(p.join(Directory.current.path, 'foo'), 'foo');

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv =
            const CliInvocation(commandPath: ['group'], positionals: ['foo']);
        final code = await GroupCommand.run(
          inv: inv,
          out: outCap.sink,
          err: errCap.sink,
          prompter: FakePrompter(),
        );
        expect(code, 2);
        expect(errCap.text,
            contains('Cannot create group with same name as a package'));
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
