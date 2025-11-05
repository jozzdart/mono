import 'dart:math';
import '../style/theme.dart';

class Hints {
  /// Simple builder for standard bullet-separated line (legacy)
  static String bullets(List<String> segments, PromptTheme theme,
      {bool dim = false}) {
    final color = dim ? theme.dim : theme.gray;
    return '$color${segments.join(' • ')}${theme.reset}';
  }

  /// New: Multi-column aligned hints for a more professional look
  static String grid(List<List<String>> rows, PromptTheme theme) {
    final buffer = StringBuffer();
    final color = theme.gray;

    // Compute column widths for alignment
    final col1Width = rows.fold<int>(
        0, (w, row) => max(w, (row.isNotEmpty ? row[0].length : 0)));
    final col2Width = rows.fold<int>(
        0, (w, row) => max(w, row.length > 1 ? row[1].length : 0));

    buffer.writeln('${theme.dim}Controls:${theme.reset}');
    for (final row in rows) {
      final key = row.isNotEmpty ? row[0].padRight(col1Width + 2) : '';
      final action = row.length > 1 ? row[1].padRight(col2Width + 2) : '';
      buffer.writeln('  $color$key${theme.reset}$action');
    }
    return buffer.toString().trimRight();
  }

  /// Compact, sectioned hint groups for a more framed feel
  static String sections(Map<String, List<String>> groups, PromptTheme theme) {
    final buffer = StringBuffer();
    final color = theme.gray;

    buffer.writeln('${theme.dim}Controls${theme.reset}');
    buffer.writeln('${theme.dim}────────────────────${theme.reset}');
    for (final entry in groups.entries) {
      buffer.writeln(
          ' ${theme.bold}${entry.key}:${theme.reset}  ${color}${entry.value.join('   ')}${theme.reset}');
    }
    return buffer.toString();
  }

  static String key(String label, PromptTheme theme) {
    return '[${theme.keyAccent}$label${theme.reset}]';
  }

  static String hint(String keyLabel, String action, PromptTheme theme) {
    return '${key(keyLabel, theme)} $action';
  }

  /// Builds a dim, parenthesized comma-separated hint string.
  /// Example: "(Enter to confirm, Esc to cancel)"
  static String comma(List<String> segments, PromptTheme theme) {
    return '${theme.dim}(${segments.join(', ')})${theme.reset}';
  }
}
