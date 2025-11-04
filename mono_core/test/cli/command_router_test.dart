import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

// A simple fake command for testing
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

// A simple fake router to validate the CommandRouter contract.
class _FakeCommandRouter implements CommandRouter {
  _FakeCommandRouter({
    required this.commands,
    required this.helpCommand,
    required this.fallbackCommand,
  });

  final List<Command> commands;
  final Command helpCommand;
  final Command fallbackCommand;

  @override
  Command getCommand(CliInvocation inv) {
    if (inv.commandPath.isEmpty) return helpCommand;
    final commandName = inv.commandPath.first;
    final command = commands
        .where((c) => c.name == commandName || c.aliases.contains(commandName))
        .firstOrNull;
    if (command == null) return fallbackCommand;
    return command;
  }

  @override
  List<Command> getAllCommands() => commands;

  @override
  String getUnknownCommandHelpHint() => helpCommand.name;
}

void main() {
  group('CommandRouter contract', () {
    test('getCommand returns help command for empty command path', () {
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = _FakeCommandRouter(
        commands: [],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final inv = const CliInvocation(commandPath: []);
      final command = router.getCommand(inv);
      expect(command, same(helpCommand));
    });

    test('getCommand returns registered command by name', () {
      final helloCommand = const _TestCommand(name: 'hello');
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = _FakeCommandRouter(
        commands: [helloCommand],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      final inv = const CliInvocation(commandPath: ['hello']);
      final command = router.getCommand(inv);
      expect(command, same(helloCommand));
    });

    test('getCommand returns registered command by alias', () {
      final versionCommand = const _TestCommand(
        name: 'version',
        aliases: ['--version', '-v'],
      );
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = _FakeCommandRouter(
        commands: [versionCommand],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );

      final command1 =
          router.getCommand(const CliInvocation(commandPath: ['--version']));
      final command2 =
          router.getCommand(const CliInvocation(commandPath: ['-v']));
      expect(command1, same(versionCommand));
      expect(command2, same(versionCommand));
    });

    test('getCommand returns fallback command for unknown command', () {
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = _FakeCommandRouter(
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
      final router = _FakeCommandRouter(
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
      final router = _FakeCommandRouter(
        commands: [],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      expect(router.getUnknownCommandHelpHint(), 'help');
    });

    test('aliases are matched correctly when multiple commands exist', () {
      final cmd1 = const _TestCommand(name: 'a', aliases: ['x']);
      final cmd2 = const _TestCommand(name: 'b', aliases: ['x']);
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = _FakeCommandRouter(
        commands: [cmd1, cmd2],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );
      // When multiple commands share an alias, firstOrNull returns the first match
      final command =
          router.getCommand(const CliInvocation(commandPath: ['x']));
      expect(command, same(cmd1));
    });
  });
}
