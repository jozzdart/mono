import '../style/theme.dart';

/// Returns a line prefixed with the themed gutter.
/// If [content] is empty/whitespace, only the gutter is returned.
String gutterLine(PromptTheme theme, String content) {
  final s = theme.style;
  final gutter = '${theme.gray}${s.borderVertical}${theme.reset}';
  if (content.trim().isEmpty) return gutter;
  return '$gutter $content';
}

/// Formats a section header label using the theme's accent and bold.
String sectionHeader(PromptTheme theme, String name) {
  return '${theme.bold}${theme.accent}$name${theme.reset}';
}

/// Formats a metric line as "Label: Value", respecting optional [color].
String metric(
  PromptTheme theme,
  String label,
  String value, {
  String? color,
}) {
  final c = color ?? '';
  final end = color != null ? theme.reset : '';
  return '${theme.dim}$label:${theme.reset} $c$value$end';
}

/// Removes ANSI escape codes from [input].
String stripAnsi(String input) {
  final ansi = RegExp(r'\x1B\[[0-9;]*m');
  return input.replaceAll(ansi, '');
}

/// Returns the visible (printable) character count of [s] after stripping ANSI.
int visibleLength(String s) {
  return stripAnsi(s).runes.length;
}
