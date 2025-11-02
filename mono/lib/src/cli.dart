import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import 'commands/setup.dart';
import 'commands/scan.dart';
import 'commands/get.dart';
import 'commands/list.dart';

@immutable
class CliWiring {
  const CliWiring({
    required this.parser,
    required this.configLoader,
    required this.configValidator,
    required this.packageScanner,
    required this.graphBuilder,
    required this.targetSelector,
    required this.commandPlanner,
    required this.clock,
    required this.logger,
    required this.pathService,
    required this.platform,
  });

  final CliParser parser;
  final ConfigLoader configLoader;
  final ConfigValidator configValidator;
  final PackageScanner packageScanner;
  final GraphBuilder graphBuilder;
  final TargetSelector targetSelector;
  final CommandPlanner commandPlanner;
  final Clock clock;
  final Logger logger;
  final PathService pathService;
  final PlatformInfo platform;
}

Future<int> runCli(
  List<String> argv,
  IOSink out,
  IOSink err, {
  CliWiring? wiring,
}) async {
  try {
    final parser = wiring?.parser ?? const ArgsCliParser();
    final inv = parser.parse(argv);
    if (inv.commandPath.isEmpty ||
        inv.commandPath.first == 'help' ||
        inv.commandPath.first == '--help' ||
        inv.commandPath.first == '-h') {
      out.writeln(_helpText);
      return 0;
    }
    final cmd = inv.commandPath.first;
    if (cmd == 'setup') return SetupCommand.run(inv: inv, out: out, err: err);
    if (cmd == 'scan') return ScanCommand.run(inv: inv, out: out, err: err);
    if (cmd == 'get') return GetCommand.run(inv: inv, out: out, err: err);
    if (cmd == 'list') return ListCommand.run(inv: inv, out: out, err: err);
    err.writeln('Unknown command: ${inv.commandPath.join(' ')}');
    err.writeln('Use `mono help`');
    return 1;
  } catch (e, st) {
    err.writeln('mono failed: $e');
    err.writeln(st);
    return 1;
  }
}

const String _helpText = 'mono - Manage Dart/Flutter monorepos\n\n'
    'Usage:\n'
    '  mono setup\n'
    '  mono scan\n'
    '  mono get [targets]\n'
    '  mono list packages|groups|tasks\n'
    '  mono help\n';
