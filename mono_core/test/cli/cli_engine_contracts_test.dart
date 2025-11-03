import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class _DummyEngine implements CliEngine {
  List<String>? lastArgv;
  CliParser? lastParser;
  Logger? lastLogger;
  void Function(CommandRouter router)? lastRegister;
  String Function()? lastHelpText;
  Future<int?> Function({required CliInvocation inv, required Logger logger})?
      lastFallback;
  String? lastHint;
  CommandRouter? registerRouter;
  bool fallbackCalled = false;

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
  }) async {
    lastArgv = argv;
    lastParser = parser;
    lastLogger = logger;
    lastRegister = register;
    lastHelpText = helpText;
    lastFallback = fallback;
    lastHint = unknownCommandHelpHint;

    // Exercise the Register callback with a dummy router.
    final router = _DummyRouter();
    registerRouter = router;
    register(router);

    // Exercise the fallback signature if provided.
    if (fallback != null) {
      fallbackCalled = true;
      await fallback(
        inv: const CliInvocation(commandPath: ['help']),
        logger: logger,
      );
    }

    return 0;
  }
}

class _DummyParser implements CliParser {
  const _DummyParser();
  @override
  CliInvocation parse(List<String> argv, {CliCommandTree? commandTree}) {
    return CliInvocation(commandPath: argv.isEmpty ? ['help'] : [argv.first]);
  }
}

class _DummyLogger implements Logger {
  const _DummyLogger();
  final List<String> messages = const [];
  @override
  void log(String message, {String? scope, String level = 'info'}) {}
}

class _DummyRouter implements CommandRouter {
  final Map<String, CommandHandler> handlers = <String, CommandHandler>{};
  @override
  void register(String name, CommandHandler handler,
      {List<String> aliases = const []}) {
    handlers[name] = handler;
    for (final a in aliases) {
      handlers[a] = handler;
    }
  }

  @override
  Future<int?> tryDispatch({
    required CliInvocation inv,
    required Logger logger,
  }) async {
    return null;
  }
}

void main() {
  group('CliEngine contracts', () {
    test('can be implemented and invoked', () async {
      final engine = _DummyEngine();
      final parser = const _DummyParser();
      final logger = const _DummyLogger();

      bool registerCalled = false;

      final code = await engine.run(
        ['cmd'],
        parser: parser,
        logger: logger,
        register: (router) {
          registerCalled = true;
          (router as _DummyRouter).register('x', (
              {required CliInvocation inv, required Logger logger}) async {
            return 0;
          }, aliases: const ['y']);
        },
        helpText: () => 'help',
        fallback: ({required inv, required logger}) async => null,
        unknownCommandHelpHint: 'mono help',
      );

      expect(code, 0);
      expect(engine.lastArgv, ['cmd']);
      expect(engine.lastParser, same(parser));
      expect(engine.lastLogger, same(logger));
      expect(registerCalled, isTrue);
      expect(engine.registerRouter, isA<_DummyRouter>());
      expect((engine.registerRouter as _DummyRouter).handlers.keys,
          containsAll(['x', 'y']));
      expect(engine.lastHint, 'mono help');
    });

    test('default unknownCommandHelpHint is "help" when omitted', () async {
      final engine = _DummyEngine();
      final parser = const _DummyParser();
      final logger = const _DummyLogger();

      await engine.run(
        [],
        parser: parser,
        logger: logger,
        register: (_) {},
        helpText: null,
        fallback: null,
      );

      expect(engine.lastHint, 'help');
    });

    test('fallback function type is callable', () async {
      final engine = _DummyEngine();
      final parser = const _DummyParser();
      final logger = const _DummyLogger();

      bool fallbackCalled = false;
      await engine.run(
        ['anything'],
        parser: parser,
        logger: logger,
        register: (_) {},
        fallback: ({required inv, required logger}) async {
          fallbackCalled = true;
          return null;
        },
      );

      expect(engine.fallbackCalled, isTrue);
      expect(fallbackCalled, isTrue);
    });
  });
}


