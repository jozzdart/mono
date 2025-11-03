import 'package:mono_core/mono_core.dart';

class LogEntry {
  LogEntry(this.message, {this.scope, this.level = 'info'});
  final String message;
  final String? scope;
  final String level;
}

class RecordingLogger implements Logger {
  final List<LogEntry> entries = <LogEntry>[];

  @override
  void log(String message, {String? scope, String level = 'info'}) {
    entries.add(LogEntry(message, scope: scope, level: level));
  }

  List<LogEntry> byLevel(String level) =>
      entries.where((e) => e.level == level).toList(growable: false);
}

class RunCall {
  RunCall(this.command, this.cwd, this.env);
  final List<String> command;
  final String? cwd;
  final Map<String, String>? env;
}

class StubProcessRunner implements ProcessRunner {
  StubProcessRunner({List<int>? returnCodes})
      : _returnCodes = List<int>.from(returnCodes ?? const <int>[0]);

  final List<int> _returnCodes; // queue
  final List<RunCall> calls = <RunCall>[];

  // Optional simulated output per invocation
  final List<List<String>> stdoutPerCall = <List<String>>[];
  final List<List<String>> stderrPerCall = <List<String>>[];

  @override
  Future<int> run(
    List<String> command, {
    String? cwd,
    Map<String, String>? env,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    calls.add(RunCall(List<String>.from(command), cwd,
        env == null ? null : Map<String, String>.from(env)));

    final index = calls.length - 1;
    final out =
        index < stdoutPerCall.length ? stdoutPerCall[index] : const <String>[];
    final err =
        index < stderrPerCall.length ? stderrPerCall[index] : const <String>[];
    for (final line in out) {
      onStdout?.call(line);
    }
    for (final line in err) {
      onStderr?.call(line);
    }

    if (_returnCodes.isEmpty) return 0;
    return _returnCodes.length == 1
        ? _returnCodes.first
        : _returnCodes.removeAt(0);
  }
}

class TestTaskPlugin extends TaskPlugin {
  TestTaskPlugin(String id,
      {bool Function(CommandId id)? supports,
      Future<int> Function(TaskInvocation i)? onExecute})
      : _supports = supports ?? ((_) => true),
        _onExecute = onExecute ?? ((_) async => 0),
        super(PluginId(id));

  final bool Function(CommandId id) _supports;
  final Future<int> Function(TaskInvocation i) _onExecute;

  @override
  bool supports(CommandId commandId) => _supports(commandId);

  @override
  Future<int> execute({
    required CommandId commandId,
    required MonoPackage package,
    required ProcessRunner processRunner,
    required Logger logger,
    Map<String, String> env = const {},
  }) {
    return _onExecute(TaskInvocation(
      commandId: commandId,
      package: package,
      processRunner: processRunner,
      logger: logger,
      env: env,
    ));
  }
}

class TaskInvocation {
  TaskInvocation({
    required this.commandId,
    required this.package,
    required this.processRunner,
    required this.logger,
    required this.env,
  });
  final CommandId commandId;
  final MonoPackage package;
  final ProcessRunner processRunner;
  final Logger logger;
  final Map<String, String> env;
}

MonoPackage pkg(
  String name, {
  String path = '.',
  PackageKind kind = PackageKind.dart,
  Set<PackageName> deps = const <PackageName>{},
  Set<String> tags = const <String>{},
}) =>
    MonoPackage(
      name: PackageName(name),
      path: path,
      kind: kind,
      localDependencies: deps,
      tags: tags,
    );
