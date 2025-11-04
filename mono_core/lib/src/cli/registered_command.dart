import 'package:mono_core/mono_core.dart';

/// Contract for a declarative CLI command with metadata and a unified run API.
abstract class Command {
  const Command();

  /// The primary token used to invoke this command.
  String get name;

  /// One-line description for help output.
  String get description;

  /// Optional aliases that map to the same command.
  List<String> get aliases => const <String>[];

  /// Unified execution entrypoint, implemented by commands.
  Future<int> run(
    CliContext context,
  );
}
