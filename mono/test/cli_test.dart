import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mono/src/cli.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

class _BufferConsumer implements StreamConsumer<List<int>> {
  _BufferConsumer(this.buffer);
  final StringBuffer buffer;
  @override
  Future addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      buffer.write(utf8.decode(chunk));
    }
  }

  @override
  Future close() async {}
}

IOSink _makeSink(StringBuffer b) => IOSink(_BufferConsumer(b));

CliWiring _makeWiring() {
  return CliWiring(
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
    prompter: const ConsolePrompter(),
    versionInfo: const StaticVersionInfo(name: 'mono', version: '9.9.9'),
    groupStoreFactory: (monocfgPath) => FileGroupStore(
      FileListConfigFolder(basePath: '$monocfgPath/groups'),
    ),
    envBuilder: const DefaultCommandEnvironmentBuilder(),
    plugins: PluginRegistry({}),
    workspaceConfig: const FileWorkspaceConfig(),
    taskExecutor: const DefaultTaskExecutor(),
  );
}

void main() {
  group('runCli help and unknown', () {
    test('prints help and returns 0 when no args', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final code = await runCli([], _makeSink(outB), _makeSink(errB),
          wiring: _makeWiring());
      expect(code, 0);
      final s = outB.toString();
      expect(s, contains('mono - Manage Dart/Flutter monorepos'));
      expect(s, contains('Usage:'));
      expect(errB.toString(), isEmpty);
    });

    test('prints help and returns 0 for --help', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final code = await runCli(['--help'], _makeSink(outB), _makeSink(errB));
      expect(code, 0);
      expect(outB.toString(), contains('Usage:'));
      expect(errB.toString(), isEmpty);
    });

    test('prints version when --version is passed', () async {
      final wiring = _makeWiring();
      final outB = StringBuffer();
      final errB = StringBuffer();
      final code = await runCli(['--version'], _makeSink(outB), _makeSink(errB),
          wiring: wiring);
      expect(code, 0);
      expect(outB.toString().trim(), 'mono 9.9.9');
      expect(errB.toString(), isEmpty);
    });

    test('unknown command returns 1 and suggests help', () async {
      final wiring = _makeWiring();
      final outB = StringBuffer();
      final errB = StringBuffer();
      final code = await runCli([
        'this_command_does_not_exist_12345'
      ], _makeSink(outB), _makeSink(errB), wiring: wiring);
      expect(code, 1);
      expect(errB.toString(),
          contains('Unknown command: this_command_does_not_exist_12345'));
      expect(errB.toString(), contains('Use `mono help`'));
      expect(outB.toString(), isEmpty);
    });
  });
}
