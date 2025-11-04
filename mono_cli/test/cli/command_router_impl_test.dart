import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

// A simple test command for testing
class _TestCommand extends Command {
  const _TestCommand({
    required this.name,
    this.aliases = const [],
  });

  @override
  final String name;

  @override
  final List<String> aliases;

  @override
  String get description => 'Test command';

  @override
  Future<int> run(CliContext context) async {
    return 0;
  }
}

void main() {
  group('DefaultCommandRouter', () {
    test('getCommand returns registered command by name', () {
      final helloCommand = const _TestCommand(name: 'hello');
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [helloCommand],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final inv = const CliInvocation(commandPath: ['hello']);
      final command = router.getCommand(inv);
      expect(command, same(helloCommand));
    });

    test('getCommand returns help command for empty command path', () {
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final inv = const CliInvocation(commandPath: []);
      final command = router.getCommand(inv);
      expect(command, same(helpCommand));
    });

    test('getCommand returns fallback command for unknown command', () {
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final inv = const CliInvocation(commandPath: ['nope']);
      final command = router.getCommand(inv);
      expect(command, same(fallbackCommand));
    });

    test('getAllCommands returns all registered commands', () {
      final cmd1 = const _TestCommand(name: 'cmd1');
      final cmd2 = const _TestCommand(name: 'cmd2');
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [cmd1, cmd2],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final allCommands = router.getAllCommands();
      expect(allCommands, [cmd1, cmd2]);
    });

    test('getUnknownCommandHelpHint returns help command name', () {
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      expect(router.getUnknownCommandHelpHint(), 'help');
    });

    test('only first token is used for command lookup (subcommands ignored)',
        () {
      final rootCommand = const _TestCommand(name: 'root');
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [rootCommand],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final command = router.getCommand(
          const CliInvocation(commandPath: ['root', 'sub', 'leaf']));
      expect(command, same(rootCommand));
    });

    test('case sensitivity: different case does not match', () {
      final helloCommand = const _TestCommand(name: 'hello');
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [helloCommand],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final command =
          router.getCommand(const CliInvocation(commandPath: ['Hello']));
      expect(command, same(fallbackCommand));
    });

    test('matches command by name only (aliases not checked)', () {
      final versionCommand = const _TestCommand(
        name: 'version',
        aliases: ['--version', '-v'],
      );
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [versionCommand],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      // The implementation only checks name, not aliases
      final command1 =
          router.getCommand(const CliInvocation(commandPath: ['version']));
      final command2 =
          router.getCommand(const CliInvocation(commandPath: ['-v']));
      expect(command1, same(versionCommand));
      expect(command2, same(fallbackCommand)); // alias not matched
    });
  });
}
