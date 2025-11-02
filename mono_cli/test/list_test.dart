import 'dart:convert';
import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  test('mono list packages prints found packages', () async {
    final tmp = await Directory.systemTemp.createTemp('mono_cli_test_');
    try {
      final aDir = Directory('${tmp.path}/packages/a');
      final bDir = Directory('${tmp.path}/packages/b');
      await aDir.create(recursive: true);
      await bDir.create(recursive: true);
      await File('${aDir.path}/pubspec.yaml').writeAsString('name: a\n');
      await File('${bDir.path}/pubspec.yaml')
          .writeAsString('name: b\nflutter:\n  uses-material-design: true\n');

      final prev = Directory.current;
      Directory.current = tmp.path;
      final out = StringBuffer();
      final code = await runCli(
          ['list', 'packages'], _BufferSink(out), _BufferSink(StringBuffer()));
      expect(code, 0);
      expect(out.toString(), contains('a'));
      expect(out.toString(), contains('b'));
      Directory.current = prev;
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}

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
  void writeAll(Iterable objects, [String sep = '']) =>
      _buffer.writeAll(objects, sep);
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
