import 'dart:io';
import 'dart:convert';

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

import 'package:mono/src/commands/group.dart';
import 'package:mono/src/commands/ungroup.dart';

class _BufferSink implements IOSink {
  _BufferSink(this._buffer);
  final StringBuffer _buffer;
  @override
  void writeln([Object? obj = '']) => _buffer.writeln(obj);
  @override
  void write(Object? obj) => _buffer.write(obj);
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> close() async {}
  @override
  Future<void> flush() async {}
  @override
  void writeAll(Iterable objects, [String sep = '']) => _buffer.writeAll(objects, sep);
  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);
  void writeFrom(List<int> data, [int start = 0, int? end]) {}
  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding e) {}
  @override
  Future<void> get done => Future.value();
}

class _FakePrompter implements Prompter {
  _FakePrompter({this.confirmValue = true, this.indices = const <int>[]});
  final bool confirmValue;
  final List<int> indices;
  @override
  Future<bool> confirm(String message, {bool defaultValue = false}) async => confirmValue;
  @override
  Future<List<int>> checklist({required String title, required List<String> items}) async => indices;
}

void main() {
  test('group cannot collide with package name', () async {
    final tmp = await Directory.systemTemp.createTemp('mono_group_test_');
    try {
      // Scaffold config
      await File('${tmp.path}/mono.yaml').writeAsString('''# mono configuration
settings:
  monocfgPath: monocfg
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
''');
      final monocfg = Directory('${tmp.path}/monocfg');
      await monocfg.create(recursive: true);
      await File('${monocfg.path}/mono_projects.yaml').writeAsString('''packages:
  - name: app
    path: packages/app
    kind: dart
''');
      final prev = Directory.current;
      Directory.current = tmp.path;
      final out = StringBuffer();
      final code = await GroupCommand.run(
        inv: const CliInvocation(commandPath: ['group'], positionals: ['app']),
        out: _BufferSink(out),
        err: _BufferSink(StringBuffer()),
        prompter: _FakePrompter(),
      );
      expect(code, 2);
      Directory.current = prev;
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('group creation writes selected members', () async {
    final tmp = await Directory.systemTemp.createTemp('mono_group_test_');
    try {
      await File('${tmp.path}/mono.yaml').writeAsString('''# mono configuration
settings:
  monocfgPath: monocfg
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
''');
      final monocfg = Directory('${tmp.path}/monocfg');
      await monocfg.create(recursive: true);
      await File('${monocfg.path}/mono_projects.yaml').writeAsString('''packages:
  - name: app
    path: packages/app
    kind: dart
  - name: core
    path: packages/core
    kind: dart
''');
      final prev = Directory.current;
      Directory.current = tmp.path;
      final out = StringBuffer();
      final code = await GroupCommand.run(
        inv: const CliInvocation(commandPath: ['group'], positionals: ['ui']),
        out: _BufferSink(out),
        err: _BufferSink(StringBuffer()),
        prompter: _FakePrompter(indices: [0]), // select 'app'
      );
      expect(code, 0);
      final groupFile = File('${tmp.path}/monocfg/groups/ui.list');
      expect(await groupFile.exists(), isTrue);
      final contents = await groupFile.readAsString();
      expect(contents, contains('app'));
      Directory.current = prev;
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('ungroup removes group after confirmation', () async {
    final tmp = await Directory.systemTemp.createTemp('mono_group_test_');
    try {
      await File('${tmp.path}/mono.yaml').writeAsString('''# mono configuration
settings:
  monocfgPath: monocfg
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
''');
      final groupsDir = Directory('${tmp.path}/monocfg/groups');
      await groupsDir.create(recursive: true);
      await File('${groupsDir.path}/ui.list').writeAsString('app\n');
      final prev = Directory.current;
      Directory.current = tmp.path;
      final out = StringBuffer();
      final code = await UngroupCommand.run(
        inv: const CliInvocation(commandPath: ['ungroup'], positionals: ['ui']),
        out: _BufferSink(out),
        err: _BufferSink(StringBuffer()),
        prompter: _FakePrompter(confirmValue: true),
      );
      expect(code, 0);
      expect(await File('${tmp.path}/monocfg/groups/ui.list').exists(), isFalse);
      Directory.current = prev;
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}


