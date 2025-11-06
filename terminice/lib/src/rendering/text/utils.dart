import '../../system/rendering.dart' as style_helpers;

int visibleLength(String s) => style_helpers.stripAnsi(s).runes.length;

List<String> wrapAnsi(String s, int maxWidth) {
  if (maxWidth <= 0) return [s];
  final raw = style_helpers.stripAnsi(s);
  if (raw.runes.length <= maxWidth) return [s];

  final out = <String>[];
  String current = '';
  int currentLen = 0;
  final codeUnits = s.codeUnits;
  int i = 0;
  while (i < codeUnits.length) {
    final ch = String.fromCharCode(codeUnits[i]);
    // Treat ESC sequences as zero-length tokens we keep intact.
    if (ch == '\u001B') {
      final start = i;
      i++;
      while (i < codeUnits.length && codeUnits[i] != 109) { // 'm'
        i++;
      }
      if (i < codeUnits.length) i++; // include 'm'
      current += String.fromCharCodes(codeUnits.getRange(start, i));
      continue;
    }
    final nextLen = currentLen + 1;
    if (nextLen > maxWidth) {
      out.add(current);
      current = '';
      currentLen = 0;
      if (ch == ' ') {
        i++;
        continue;
      }
    }
    current += ch;
    currentLen++;
    i++;
  }
  if (current.isNotEmpty) out.add(current);
  return out;
}


