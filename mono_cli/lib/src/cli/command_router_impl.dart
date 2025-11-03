import 'package:mono_core/mono_core.dart';

@immutable
class DefaultCommandRouter implements CommandRouter {
  final Command helpCommand;
  final List<Command> commands;
  final Command fallbackCommand;

  const DefaultCommandRouter({
    required this.commands,
    required this.fallbackCommand,
    required this.helpCommand,
  });

  @override
  Command getCommand(CliInvocation inv) {
    if (inv.commandPath.isEmpty) return helpCommand;
    final commandName = inv.commandPath.first;
    final command = commands.where((c) => c.name == commandName).firstOrNull;
    if (command == null) return fallbackCommand;
    return command;
  }

  @override
  List<Command> getAllCommands() => commands;

  @override
  String getUnknownCommandHelpHint() => helpCommand.name;
}
