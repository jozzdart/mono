import 'package:mono_core/mono_core.dart';

abstract class CliEngine {
  const CliEngine();

  Future<int> run(
    List<String> argv, {
    required CliParser parser,
    required Logger logger,
    required void Function(CommandRouter router) register,
    String Function()? helpText,
    Future<int?> Function({
      required CliInvocation inv,
      required Logger logger,
    })? fallback,
    String unknownCommandHelpHint = 'help',
  });
}
