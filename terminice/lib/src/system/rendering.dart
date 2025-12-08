import '../style/theme.dart';

/// Returns a line prefixed with the themed gutter.
/// If [content] is empty/whitespace, only the gutter is returned.
///
/// Note: Prefer using [LineBuilder.gutter()] for new code. This function
/// is retained for backwards compatibility with existing code.
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
