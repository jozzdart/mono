import 'package:mono_core/mono_core.dart';

@immutable
class CliWiring {
  const CliWiring({
    required this.parser,
    required this.configLoader,
    required this.packageScanner,
    required this.graphBuilder,
    required this.targetSelector,
    required this.commandPlanner,
    required this.clock,
    required this.logger,
    required this.pathService,
    required this.prompter,
    required this.envBuilder,
    required this.plugins,
    required this.workspaceConfig,
    required this.taskExecutor,
    required this.router,
  });

  final CliParser parser;
  final ConfigLoader configLoader;
  final PackageScanner packageScanner;
  final GraphBuilder graphBuilder;
  final TargetSelector targetSelector;
  final CommandPlanner commandPlanner;
  final Clock clock;
  final Logger logger;
  final PathService pathService;
  final Prompter prompter;
  final CommandEnvironmentBuilder envBuilder;
  final PluginResolver plugins;
  final WorkspaceConfig workspaceConfig;
  final TaskExecutor taskExecutor;
  final CommandRouter router;
}

Future<int> runCli(List<String> argv, {required CliWiring wiring}) async {
  final invocation = wiring.parser.parse(argv);

  final ctx = CliContext(
    invocation: invocation,
    workspaceConfig: wiring.workspaceConfig,
    envBuilder: wiring.envBuilder,
    plugins: wiring.plugins,
    executor: wiring.taskExecutor,
    packageScanner: wiring.packageScanner,
    graphBuilder: wiring.graphBuilder,
    targetSelector: wiring.targetSelector,
    commandPlanner: wiring.commandPlanner,
    clock: wiring.clock,
    pathService: wiring.pathService,
    prompter: wiring.prompter,
    logger: wiring.logger,
    router: wiring.router,
  );

  try {
    final command = ctx.router.getCommand(invocation);
    return await command.run(ctx);
  } catch (e, st) {
    wiring.logger.log('CLI failed: $e', level: 'error');
    wiring.logger.log('$st', level: 'error');
    return 1;
  }
}
