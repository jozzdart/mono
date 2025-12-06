import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/prompt_runner.dart';

/// CheatSheet – command list with shortcuts and usage.
///
/// Designed to align with ThemeDemo styling: framed title line,
/// subtle separators, accent headers, and tasteful dim text.
class CheatSheet {
  /// Title at the top of the sheet.
  final String title;

  /// Rows of [command, shortcut, usage].
  final List<List<String>> entries;

  /// Visual theme.
  final PromptTheme theme;

  CheatSheet(
    this.entries, {
    this.title = 'Cheat Sheet',
    this.theme = PromptTheme.dark,
  });

  /// Renders the cheat sheet once. Non-interactive.
  void show() {
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    // Header
    final frame = FramedLayout(title, theme: theme);
    out.writeln('${theme.bold}${frame.top()}${theme.reset}');

    // Table body: Command | Shortcut | Usage (custom, inline rendering)
    final style = theme.style;
    final columns = const ['Command', 'Shortcut', 'Usage'];

    // Compute column widths
    int visibleLen(String s) => s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').length;
    final widths = <int>[
      visibleLen(columns[0]),
      visibleLen(columns[1]),
      visibleLen(columns[2]),
    ];
    for (final row in entries) {
      if (row.isEmpty) continue;
      widths[0] = max(widths[0], visibleLen(row[0]));
      widths[1] = max(widths[1], visibleLen(row.length > 1 ? row[1] : ''));
      widths[2] = max(widths[2], visibleLen(row.length > 2 ? row[2] : ''));
    }

    String padLeftAlign(String s, int w) {
      final pad = max(0, w - visibleLen(s));
      return s + ' ' * pad;
    }

    String padCenter(String s, int w) {
      final pad = max(0, w - visibleLen(s));
      final left = pad ~/ 2;
      final right = pad - left;
      return (' ' * left) + s + (' ' * right);
    }

    // Header row
    final header = StringBuffer();
    header.write('${theme.gray}${style.borderVertical}${theme.reset} ');
    header.write('${theme.bold}${theme.accent}${padLeftAlign(columns[0], widths[0])}${theme.reset}');
    header.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
    header.write('${theme.bold}${theme.accent}${padCenter(columns[1], widths[1])}${theme.reset}');
    header.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
    header.write('${theme.bold}${theme.accent}${padLeftAlign(columns[2], widths[2])}${theme.reset}');
    out.writeln(header.toString());

    // Connector line (sized to table width)
    final tableWidth = 2 + widths.fold<int>(0, (sum, w) => sum + w) + 2 * 3; // 3 cols => 2 separators
    out.writeln('${theme.gray}${style.borderConnector}${'─' * tableWidth}${theme.reset}');

    // Rows (zebra stripes)
    for (var i = 0; i < entries.length; i++) {
      final row = entries[i];
      final stripe = (i % 2 == 1);
      final prefix = stripe ? theme.dim : '';
      final suffix = stripe ? theme.reset : '';

      final buf = StringBuffer();
      buf.write('${theme.gray}${style.borderVertical}${theme.reset} ');
      buf.write(prefix);
      buf.write(padLeftAlign(row.isNotEmpty ? row[0] : '', widths[0]));
      buf.write(suffix);
      buf.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
      buf.write(prefix);
      buf.write(padCenter(row.length > 1 ? row[1] : '', widths[1]));
      buf.write(suffix);
      buf.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
      buf.write(prefix);
      buf.write(padLeftAlign(row.length > 2 ? row[2] : '', widths[2]));
      buf.write(suffix);
      out.writeln(buf.toString());
    }

    // Bottom border to balance the header line
    out.writeln(frame.bottom());
  }

  /// Convenience: alias to [show].
  void run() => show();
}


