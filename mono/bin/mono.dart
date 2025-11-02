import 'dart:io';

import 'package:mono_cli_parser_args/mono_cli_parser_args.dart';
import 'package:mono_config_yaml/mono_config_yaml.dart';
import 'package:mono_scanner_fs/mono_scanner_fs.dart';
import 'package:mono_graph_builder_impl/mono_graph_builder_impl.dart';
import 'package:mono_selector_impl/mono_selector_impl.dart';
import 'package:mono_runner/mono_runner.dart';
import 'package:mono_system_io/mono_system_io.dart';

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
