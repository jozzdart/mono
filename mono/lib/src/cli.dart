import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import 'commands/setup.dart';
import 'commands/scan.dart';
import 'commands/get.dart';
import 'commands/format.dart';
import 'commands/test.dart';
import 'commands/list.dart';
import 'commands/group.dart';
import 'commands/ungroup.dart';
import 'commands/version.dart';
import 'commands/tasks.dart';
import 'commands/task.dart';

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
    required this.prompter,
    required this.versionInfo,
    required this.groupStoreFactory,
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
  final Prompter prompter;
  final VersionInfo versionInfo;
  final GroupStore Function(String monocfgPath) groupStoreFactory;
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
    final prompter = wiring?.prompter ?? const ConsolePrompter();
    final versionInfo = wiring?.versionInfo ??
        const StaticVersionInfo(name: 'mono', version: 'unknown');
    if (cmd == 'version' || cmd == '--version' || cmd == '-v' || cmd == '--v') {
      return VersionCommand.run(
          inv: inv, out: out, err: err, version: versionInfo);
    }
    if (cmd == 'setup') return SetupCommand.run(inv: inv, out: out, err: err);
    if (cmd == 'scan') return ScanCommand.run(inv: inv, out: out, err: err);
    if (cmd == 'get') {
      return GetCommand.run(
        inv: inv,
        out: out,
        err: err,
        groupStoreFactory: wiring!.groupStoreFactory,
      );
    }
    if (cmd == 'format') {
      return FormatCommand.run(
        inv: inv,
        out: out,
        err: err,
        groupStoreFactory: wiring!.groupStoreFactory,
      );
    }
    if (cmd == 'test') {
      return TestCommand.run(
        inv: inv,
        out: out,
        err: err,
        groupStoreFactory: wiring!.groupStoreFactory,
      );
    }
    if (cmd == 'list') {
      return ListCommand.run(
        inv: inv,
        out: out,
        err: err,
        groupStoreFactory: wiring!.groupStoreFactory,
      );
    }
    if (cmd == 'tasks') {
      return TasksCommand.run(inv: inv, out: out, err: err);
    }
    if (cmd == 'group') {
      return GroupCommand.run(
          inv: inv,
          out: out,
          err: err,
          prompter: prompter,
          groupStoreFactory: wiring!.groupStoreFactory);
    }
    if (cmd == 'ungroup') {
      return UngroupCommand.run(
          inv: inv,
          out: out,
          err: err,
          prompter: prompter,
          groupStoreFactory: wiring!.groupStoreFactory);
    }
    // Attempt to resolve as a task name
    final maybe = await TaskCommand.tryRun(
      inv: inv,
      out: out,
      err: err,
      groupStoreFactory: wiring!.groupStoreFactory,
    );
    if (maybe != null) return maybe;

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
    '  mono format [targets] [--check]\n'
    '  mono test [targets]\n'
    '  mono [taskname] [targets]\n'
    '  mono list packages|groups|tasks\n'
    '  mono tasks\n'
    '  mono group <group_name>\n'
    '  mono ungroup <group_name>\n'
    '  mono version | -v | --version\n'
    '  mono help\n\n'
    'Notes:\n'
    '- Built-in commands like get run on all packages when no targets are given.\n'
    '- External tasks require explicit targets; use "all" to run on all packages.';
