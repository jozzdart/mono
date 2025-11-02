import 'package:mono/src/commands/tasks.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../util/fs_fixtures.dart';
import '../util/fakes.dart';

void main() {
  late WorkspaceConfig workspaceConfig;

  setUp(() async {
    workspaceConfig = const FileWorkspaceConfig();
  });

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

        final outB = StringBuffer();
        final errB = StringBuffer();
        final inv = const CliInvocation(commandPath: ['tasks']);
        final code = await TasksCommand.run(
            inv: inv,
            logger: BufferingLogger(outB, errB),
            workspaceConfig: workspaceConfig);
        expect(code, 0);
        final out = outB.toString();
        expect(out, contains('- fmt (plugin: format)'));
        expect(out, contains('- clean (plugin: pub)'));
        expect(out, contains('- build (plugin: exec)'));
        expect(errB.toString().trim(), isEmpty);
      } finally {
        ws.exit();
        ws.dispose();
      }
    });
  });
}
