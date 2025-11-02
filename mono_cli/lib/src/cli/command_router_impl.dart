import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

@immutable
class DefaultCommandRouter implements CommandRouter {
  DefaultCommandRouter();

  final Map<String, CommandHandler> _handlers = <String, CommandHandler>{};

  @override
  void register(String name, CommandHandler handler,
      {List<String> aliases = const []}) {
    _handlers[name] = handler;
    for (final alias in aliases) {
      _handlers[alias] = handler;
    }
  }

  @override
  Future<int?> tryDispatch({
    required CliInvocation inv,
    required Logger logger,
  }) async {
    if (inv.commandPath.isEmpty) return null;
    final key = inv.commandPath.first;
    final handler = _handlers[key];
    if (handler == null) return null;
    return handler(inv: inv, logger: logger);
  }
}
