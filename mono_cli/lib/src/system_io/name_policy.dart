import 'package:mono_cli/mono_cli.dart';

class DefaultSlugNamePolicy implements NamePolicy {
  const DefaultSlugNamePolicy();

  static final RegExp _allowed = RegExp(r'^[a-z0-9][a-z0-9-_]*');

  @override
  bool isValid(String name) => _allowed.hasMatch(name);

  @override
  String normalize(String name) {
    final lower = name.trim().toLowerCase();
    final buf = StringBuffer();
    for (final codeUnit in lower.codeUnits) {
      final ch = String.fromCharCode(codeUnit);
      if (RegExp(r'[a-z0-9-]').hasMatch(ch)) {
        buf.write(ch);
      } else if (ch == ' ' || ch == '_' || ch == '.') {
        buf.write('-');
      }
    }
    var out = buf.toString();
    out = out.replaceAll(RegExp(r'-{2,}'), '-');
    out = out.replaceAll(RegExp(r'^-+'), '');
    out = out.replaceAll(RegExp(r'-+$'), '');
    return out;
  }
}
