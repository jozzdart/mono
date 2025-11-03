import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

import '../util/test_doubles.dart';

class _EmptyEnvBuilder implements CommandEnvironmentBuilder {
  const _EmptyEnvBuilder();
  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore Function(String monocfgPath) groupStoreFactory,
  }) async {
    return CommandEnvironment(
      config: const MonoConfig(include: [], exclude: []),
      monocfgPath: 'monocfg',
      packages: const [],
      graph: DependencyGraph(nodes: const {}),
      groups: const {},
      selector: const DefaultTargetSelector(),
      effectiveOrder: true,
      effectiveConcurrency: 1,
    );
  }
}

class _NoneSelector implements TargetSelector {
  const _NoneSelector();
  @override
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups,
    required DependencyGraph graph,
    required bool dependencyOrder,
  }) =>
      const [];
}

class _SingleEnvBuilder implements CommandEnvironmentBuilder {
  const _SingleEnvBuilder({this.selector = const DefaultTargetSelector()});
  final TargetSelector selector;
  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore Function(String monocfgPath) groupStoreFactory,
  }) async {
    return CommandEnvironment(
      config: const MonoConfig(include: [], exclude: []),
      monocfgPath: 'monocfg',
      packages: [pkg('a')],
      graph: DependencyGraph(nodes: {'a'}),
      groups: const {},
      selector: selector,
      effectiveOrder: true,
      effectiveConcurrency: 1,
    );
  }
}

GroupStore _groups(String path) => FileGroupStore(
      FileListConfigFolder(basePath: '$path/groups'),
    );

void main() {
  group('DefaultTaskExecutor logger levels', () {
    test('logs error when workspace empty', () async {
      final logger = RecordingLogger();
      final exec = const DefaultTaskExecutor();
      final code = await exec.execute(
        task:
            TaskSpec(id: const CommandId('get'), plugin: const PluginId('pub')),
        inv: const CliInvocation(commandPath: ['get']),
        logger: logger,
        groupStoreFactory: _groups,
        envBuilder: const _EmptyEnvBuilder(),
        plugins: PluginRegistry({}),
      );
      expect(code, 1);
      expect(logger.byLevel('error').map((e) => e.message).join('\n'),
          contains('No packages found'));
    });

    test('logs error when no targets matched', () async {
      final logger = RecordingLogger();
      final exec = const DefaultTaskExecutor();
      final code = await exec.execute(
        task:
            TaskSpec(id: const CommandId('get'), plugin: const PluginId('pub')),
        inv: const CliInvocation(commandPath: ['get'], targets: [TargetAll()]),
        logger: logger,
        groupStoreFactory: _groups,
        envBuilder: const _SingleEnvBuilder(selector: _NoneSelector()),
        plugins: PluginRegistry({}),
      );
      expect(code, 1);
      expect(logger.byLevel('error').map((e) => e.message).join('\n'),
          contains('No target packages matched'));
    });

    test('logs info for dry-run summary', () async {
      final logger = RecordingLogger();
      final exec = const DefaultTaskExecutor();
      final code = await exec.execute(
        task: TaskSpec(
            id: const CommandId('exec:echo hi'),
            plugin: const PluginId('exec')),
        inv: const CliInvocation(
          commandPath: ['build'],
          options: {
            'dry-run': ['1']
          },
          targets: [TargetAll()],
        ),
        logger: logger,
        groupStoreFactory: _groups,
        envBuilder: const _SingleEnvBuilder(),
        plugins: PluginRegistry({}),
        dryRunLabel: 'build',
      );
      expect(code, 0);
      expect(logger.byLevel('info').map((e) => e.message).join('\n'),
          contains('Would run build for 1 packages'));
    });
  });
}
