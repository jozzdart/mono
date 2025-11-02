import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import 'package:mono/src/cli.dart';

Future<void> main(List<String> argv) async {
  final wiring = CliWiring(
    parser: const ArgsCliParser(),
    configLoader: const YamlConfigLoader(),
    configValidator: const YamlConfigValidator(),
    packageScanner: const FileSystemPackageScanner(),
    graphBuilder: const DefaultGraphBuilder(),
    targetSelector: const DefaultTargetSelector(),
    commandPlanner: const DefaultCommandPlanner(),
    clock: const SystemClock(),
    logger: const StdLogger(),
    pathService: const DefaultPathService(),
    platform: const DefaultPlatformInfo(),
  );
  final exitCodeValue = await runCli(argv, stdout, stderr, wiring: wiring);
  // ignore: avoid_print
  exit(exitCodeValue);
}
