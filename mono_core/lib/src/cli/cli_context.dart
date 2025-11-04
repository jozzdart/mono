import 'package:mono_core/mono_core.dart';

/// Aggregated services available to CLI commands.
class CliContext {
  const CliContext({
    required this.invocation,
    required this.logger,
    required this.workspaceConfig,
    required this.envBuilder,
    required this.plugins,
    required this.executor,
    required this.packageScanner,
    required this.graphBuilder,
    required this.targetSelector,
    required this.commandPlanner,
    required this.clock,
    required this.pathService,
    required this.prompter,
    required this.router,
  });

  final CliInvocation invocation;
  final Logger logger;
  final WorkspaceConfig workspaceConfig;
  final CommandEnvironmentBuilder envBuilder;
  final PluginResolver plugins;
  final TaskExecutor executor;
  final PackageScanner packageScanner;
  final GraphBuilder graphBuilder;
  final TargetSelector targetSelector;
  final CommandPlanner commandPlanner;
  final Clock clock;
  final PathService pathService;
  final Prompter prompter;
  final CommandRouter router;
}
