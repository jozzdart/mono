import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class TempWorkspace {
  TempWorkspace(this.rootPath) : _prevCwd = Directory.current.path;

  final String rootPath;
  final String _prevCwd;

  void enter() {
    Directory.current = rootPath;
  }

  void exit() {
    Directory.current = _prevCwd;
  }

  void dispose() {
    try {
      Directory(rootPath).deleteSync(recursive: true);
    } catch (_) {}
  }
}

Future<TempWorkspace> createTempWorkspace([String prefix = 'mono_ws_']) async {
  final dir = await Directory.systemTemp.createTemp(prefix);
  return TempWorkspace(dir.path);
}

Future<File> writeMonoYaml({
  String path = 'mono.yaml',
  String monocfgPath = 'monocfg',
  List<String> include = const ['**'],
  List<String> exclude = const ['monocfg/**', '.dart_tool/**'],
  Map<String, List<String>> groups = const {},
  Map<String, Map<String, Object?>> tasks = const {},
}) async {
  // Start from centralized defaults and override selected fields for tests
  final base = defaultConfig();
  final taskDefs = <String, TaskDefinition>{};
  for (final e in tasks.entries) {
    final m = e.value;
    final depends = (m['dependsOn'] is List)
        ? (m['dependsOn'] as List).map((x) => '$x').toList()
        : const <String>[];
    final env = <String, String>{};
    if (m['env'] is Map) {
      for (final ev in (m['env'] as Map).entries) {
        env['${ev.key}'] = '${ev.value}';
      }
    }
    final run = (m['run'] is List)
        ? (m['run'] as List).map((x) => '$x').toList()
        : const <String>[];
    taskDefs[e.key] = TaskDefinition(
      plugin: m['plugin']?.toString(),
      dependsOn: depends,
      env: env,
      run: run,
    );
  }

  final cfg = MonoConfig(
    include: include,
    exclude: exclude,
    dartProjects: base.dartProjects,
    flutterProjects: base.flutterProjects,
    groups: groups,
    tasks: taskDefs,
    settings: base.settings,
    logger: base.logger,
  );

  final f = File(path);
  await f.writeAsString(toYaml(cfg, monocfgPath: monocfgPath));
  return f;
}

Future<void> ensureMonocfg(String monocfgPath) async {
  Directory(monocfgPath).createSync(recursive: true);
  Directory(p.join(monocfgPath, 'groups')).createSync(recursive: true);
  final tasks = File(p.join(monocfgPath, 'tasks.yaml'));
  if (!tasks.existsSync()) {
    tasks.writeAsStringSync('# tasks:\n');
  }
}

void writePubspec(String dir, String name,
    {bool flutter = false, String? depsYaml}) {
  final buf = StringBuffer()
    ..writeln('name: $name')
    ..writeln('version: 1.0.0');
  if (flutter) {
    buf.writeln('flutter: {}');
  }
  if (depsYaml != null && depsYaml.trim().isNotEmpty) {
    buf.writeln(depsYaml);
  }
  final path = p.join(dir, 'pubspec.yaml');
  File(path).createSync(recursive: true);
  File(path).writeAsStringSync(buf.toString());
}

class CapturedIo {
  final _controller = StreamController<List<int>>(sync: true);
  final _buffer = BytesBuilder();
  late final IOSink sink = IOSink(_controller.sink);

  CapturedIo() {
    _controller.stream.listen(_buffer.add);
  }

  String get text => utf8.decode(_buffer.toBytes());

  void dispose() {
    sink.close();
    _controller.close();
  }
}

Future<void> writeFile(String path, String contents) async {
  File(path).createSync(recursive: true);
  await File(path).writeAsString(contents);
}
