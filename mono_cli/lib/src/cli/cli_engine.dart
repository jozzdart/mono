import 'package:mono_core/mono_core.dart';

import 'command_router_impl.dart';

class DefaultCliEngine implements CliEngine {
  const DefaultCliEngine();

  @override
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
  }) {
    return _runCli(
      argv,
      parser: parser,
      logger: logger,
      register: register,
      helpText: helpText,
      fallback: fallback,
      unknownCommandHelpHint: unknownCommandHelpHint,
    );
  }
}

Future<int> _runCli(
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
}) async {
  try {
    final inv = parser.parse(argv);
    if (inv.commandPath.isEmpty ||
        inv.commandPath.first == 'help' ||
        inv.commandPath.first == '--help' ||
        inv.commandPath.first == '-h') {
      final text = helpText?.call();
      if (text != null && text.isNotEmpty) {
        logger.log(text);
      }
      return 0;
    }

    final router = DefaultCommandRouter();
    register(router);

    final dispatched = await router.tryDispatch(inv: inv, logger: logger);
    if (dispatched != null) return dispatched;

    if (fallback != null) {
      final maybe = await fallback(inv: inv, logger: logger);
      if (maybe != null) return maybe;
    }

    logger.log('Unknown command: ${inv.commandPath.join(' ')}', level: 'error');
    logger.log('Use `$unknownCommandHelpHint`', level: 'error');
    return 1;
  } catch (e, st) {
    logger.log('CLI failed: $e', level: 'error');
    logger.log('$st', level: 'error');
    return 1;
  }
}
