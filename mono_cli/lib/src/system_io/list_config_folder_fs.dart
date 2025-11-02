import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;

class FileListConfigFolder implements ListConfigFolder {
  FileListConfigFolder({
    required String basePath,
    NamePolicy namePolicy = const DefaultSlugNamePolicy(),
  })  : _basePath = p.normalize(basePath),
        _policy = namePolicy;

  final String _basePath;
  final NamePolicy _policy;

  String _filePathFor(String name) => p.join(_basePath, '$name.list');

  @override
  Future<bool> exists(String name) async {
    final f = File(_filePathFor(name));
    return f.exists();
  }

  @override
  Future<void> delete(String name) async {
    final f = File(_filePathFor(name));
    if (await f.exists()) {
      await f.delete();
    }
  }

  @override
  Future<List<String>> listNames() async {
    final dir = Directory(_basePath);
    if (!await dir.exists()) return const <String>[];
    final out = <String>[];
    await for (final ent in dir.list(followLinks: false)) {
      if (ent is File && ent.path.endsWith('.list')) {
        final stem = p.basenameWithoutExtension(ent.path);
        if (_policy.isValid(stem)) out.add(stem);
      }
    }
    out.sort();
    return out;
  }

  @override
  Future<List<String>> readList(String name) async {
    final f = File(_filePathFor(name));
    if (!await f.exists()) return const <String>[];
    final raw = await f.readAsLines();
    final items = <String>[];
    for (final line in raw) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('#')) continue;
      items.add(t);
    }
    return items;
  }

  @override
  Future<void> writeList(String name, List<String> items) async {
    final normalized = _policy.normalize(name);
    if (!_policy.isValid(normalized)) {
      throw ArgumentError('Invalid name "$name" (normalized: "$normalized")');
    }
    final dir = Directory(_basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final f = File(_filePathFor(normalized));
    final tmp = File('${f.path}.tmp');
    final sb = StringBuffer();
    for (final item in items) {
      final v = item.trim();
      if (v.isEmpty) continue;
      sb.writeln(v);
    }
    await tmp.writeAsString(sb.toString());
    if (await f.exists()) {
      await f.delete();
    }
    await tmp.rename(f.path);
  }
}
