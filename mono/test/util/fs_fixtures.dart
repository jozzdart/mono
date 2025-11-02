import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

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
  String quote(String v) {
    if (v.contains('#') ||
        v.contains(':') ||
        v.contains('*') ||
        v.contains(' ')) {
      return '"${v.replaceAll('"', '\\"')}"';
    }
    return v;
  }

  final sb = StringBuffer();
  sb.writeln('# mono configuration');
  sb.writeln('settings:');
  sb.writeln('  monocfgPath: $monocfgPath');
  sb.writeln('  concurrency: auto');
  sb.writeln('  defaultOrder: dependency');
  sb.writeln('include:');
  for (final g in include) {
    sb.writeln('  - ${quote(g)}');
  }
  sb.writeln('exclude:');
  for (final g in exclude) {
    sb.writeln('  - ${quote(g)}');
  }
  sb.writeln('groups:');
  if (groups.isEmpty) {
    sb.writeln('  {}');
  } else {
    for (final e in groups.entries) {
      sb.writeln('  ${e.key}:');
      for (final item in e.value) {
        sb.writeln('    - ${quote(item)}');
      }
    }
  }
  sb.writeln('tasks:');
  if (tasks.isEmpty) {
    sb.writeln('  {}');
  } else {
    for (final e in tasks.entries) {
      sb.writeln('  ${e.key}:');
      final def = e.value;
      if (def['plugin'] != null) sb.writeln('    plugin: ${def['plugin']}');
      if (def['dependsOn'] is List && (def['dependsOn'] as List).isNotEmpty) {
        sb.writeln('    dependsOn:');
        for (final d in (def['dependsOn'] as List)) {
          sb.writeln('      - ${quote('$d')}');
        }
      }
      if (def['env'] is Map && (def['env'] as Map).isNotEmpty) {
        sb.writeln('    env:');
        for (final ev in (def['env'] as Map).entries) {
          sb.writeln('      ${ev.key}: ${quote('${ev.value}')}');
        }
      }
      if (def['run'] is List && (def['run'] as List).isNotEmpty) {
        sb.writeln('    run:');
        for (final r in (def['run'] as List)) {
          sb.writeln('      - ${quote('$r')}');
        }
      }
    }
  }

  final f = File(path);
  await f.writeAsString(sb.toString());
  return f;
}

Future<void> ensureMonocfg(String monocfgPath) async {
  Directory(monocfgPath).createSync(recursive: true);
  Directory(p.join(monocfgPath, 'groups')).createSync(recursive: true);
  final projects = File(p.join(monocfgPath, 'mono_projects.yaml'));
  if (!projects.existsSync()) {
    projects.writeAsStringSync('packages: []\n');
  }
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
