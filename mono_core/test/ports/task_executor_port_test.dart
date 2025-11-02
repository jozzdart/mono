import 'dart:async';
import 'dart:io';

import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class _CapturingSink implements StreamConsumer<List<int>> {
  _CapturingSink(this.buffer);
  final StringBuffer buffer;
  @override
  Future addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      buffer.write(String.fromCharCodes(chunk));
    }
  }

  @override
  Future close() async {}
}

IOSink _makeSink(StringBuffer b) => IOSink(_CapturingSink(b));

class _FakeEnvBuilder implements CommandEnvironmentBuilder {
  const _FakeEnvBuilder(this._env);
  final CommandEnvironment _env;
  @override
  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore Function(String monocfgPath) groupStoreFactory,
  }) async {
    return _env;
  }
}

class _FakeGroupStore implements GroupStore {
  const _FakeGroupStore();
  @override
  Future<bool> exists(String groupName) async => false;
  @override
  Future<void> deleteGroup(String groupName) async {}
  @override
  Future<List<String>> listGroups() async => const [];
  @override
  Future<List<String>> readGroup(String groupName) async => const [];
  @override
  Future<void> writeGroup(String groupName, List<String> members) async {}
}

class _FakeSelector implements TargetSelector {
  const _FakeSelector();
  @override
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups,
    required DependencyGraph graph,
    required bool dependencyOrder,
  }) =>
      packages;
}

class _FakePlugins implements PluginResolver {
  const _FakePlugins();
  @override
  TaskPlugin? resolve(PluginId? id) => null;
}

class _ProbeExecutor implements TaskExecutor {
  const _ProbeExecutor();
  static Map<String, Object?> lastArgs = {};
  @override
  Future<int> execute({
    required TaskSpec task,
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    Map<String, String> env = const {},
    String? dryRunLabel,
  }) async {
    lastArgs = {
      'task': task,
      'inv': inv,
      'env': env,
      'dryRunLabel': dryRunLabel,
    };
    return 42;
  }
}

void main() {
  group('TaskExecutor port', () {
    test('execute forwards env and dryRunLabel, returns code', () async {
      final outB = StringBuffer();
      final errB = StringBuffer();
      final task =
          TaskSpec(id: const CommandId('x'), plugin: const PluginId('p'));
      final inv = const CliInvocation(commandPath: ['x']);

      final env = CommandEnvironment(
        config: const MonoConfig(include: [], exclude: []),
        monocfgPath: 'monocfg',
        packages: const [],
        graph: DependencyGraph(nodes: const {}),
        groups: const {},
        selector: const _FakeSelector(),
        effectiveOrder: true,
        effectiveConcurrency: 1,
      );

      final code = await const _ProbeExecutor().execute(
        task: task,
        inv: inv,
        out: _makeSink(outB),
        err: _makeSink(errB),
        groupStoreFactory: (_) => const _FakeGroupStore(),
        envBuilder: _FakeEnvBuilder(env),
        plugins: const _FakePlugins(),
        env: const {'A': 'B'},
        dryRunLabel: 'label',
      );

      expect(code, 42);
      expect(_ProbeExecutor.lastArgs['task'], equals(task));
      expect(_ProbeExecutor.lastArgs['inv'], equals(inv));
      expect(_ProbeExecutor.lastArgs['env'], equals(const {'A': 'B'}));
      expect(_ProbeExecutor.lastArgs['dryRunLabel'], equals('label'));
    });
  });
}
