import 'package:mono_core/mono_core.dart';

/// Signature for a command handler used by the router.
typedef CommandHandler = Future<int> Function({
  required CliInvocation inv,
  required Logger logger,
});

/// Abstract interface for a simple command router.
@immutable
abstract class CommandRouter {
  const CommandRouter();

  /// Register a command [name] with the provided [handler].
  /// Optional [aliases] map additional tokens to the same handler.
  void register(String name, CommandHandler handler,
      {List<String> aliases = const []});

  /// Attempts to dispatch the invocation to a registered command.
  /// Returns the exit code if a matching command is found, or null otherwise.
  Future<int?> tryDispatch({
    required CliInvocation inv,
    required Logger logger,
  });
}
