import 'package:mono_core/mono_core.dart';

/// Abstract interface for a simple command router.
@immutable
abstract class CommandRouter {
  const CommandRouter();

  Command getCommand(CliInvocation inv);

  List<Command> getAllCommands();

  String getUnknownCommandHelpHint();
}
