import 'package:mono/src/commands/tasks.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../util/fs_fixtures.dart';

void main() {
  group('TasksCommand', () {
    test('prints merged tasks', () async {
      final ws = await createTempWorkspace('mono_tasks_');
      ws.enter();
      try {
        await writeMonoYaml(tasks: {
          'fmt': {'plugin': 'format'},
          'clean': {'plugin': 'pub'},
        });
        await ensureMonocfg('monocfg');
        await writeFile(
          p.join('monocfg', 'tasks.yaml'),
          'build:\n  plugin: exec\n  run: ["dart compile exe bin/main.dart"]\n',
        );

        final outCap = CapturedIo();
        final errCap = CapturedIo();
        final inv = const CliInvocation(commandPath: ['tasks']);
        final code = await TasksCommand.run(
            inv: inv, out: outCap.sink, err: errCap.sink);
        expect(code, 0);
        final out = outCap.text;
        expect(out, contains('- fmt (plugin: format)'));
        expect(out, contains('- clean (plugin: pub)'));
        expect(out, contains('- build (plugin: exec)'));
        expect(errCap.text.trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
