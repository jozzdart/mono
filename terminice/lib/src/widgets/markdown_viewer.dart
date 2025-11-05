import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';

/// MarkdownViewer – renders markdown with colors and headers
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/highlight/info/warn colors
class MarkdownViewer {
  final String markdown;
  final PromptTheme theme;
  final String? title;
  final bool color;

  MarkdownViewer(
    this.markdown, {
    this.theme = const PromptTheme(),
    this.title,
    this.color = true,
  });

  void show() {
    final style = theme.style;
    final label = title ?? 'Markdown';

    final top = style.showBorder
        ? FrameRenderer.titleWithBorders(label, theme)
        : FrameRenderer.plainTitle(label, theme);
    stdout.writeln('${theme.bold}$top${theme.reset}');

    final lines = markdown.split('\n');
    bool inCode = false;
    String? codeLang;
    bool inTable = false;
    final tableLines = <String>[];

    for (final raw in lines) {
      final line = raw.replaceAll('\r', '');

      // Fenced code blocks (```lang)
      final fence = RegExp(r'^\s*```(\w+)?\s*$');
      final m = fence.firstMatch(line);
      if (m != null) {
        if (!inCode) {
          inCode = true;
          codeLang = (m.group(1) ?? '').trim().isEmpty ? null : m.group(1)!.trim();
          _gutter(_codeFenceTop(codeLang));
        } else {
          inCode = false;
          _gutter(_codeFenceBottom());
          codeLang = null;
        }
        continue;
      }

      if (inCode) {
        _gutter(_renderCodeLine(line));
        continue;
      }

      // GitHub style tables
      if (_isTableSeparator(line) || _looksLikeTableRow(line)) {
        inTable = true;
        tableLines.add(line);
        continue;
      } else if (inTable) {
        // End of table block: render accumulated lines
        for (final tl in _renderTableBlock(tableLines)) {
          _gutter(tl);
        }
        tableLines.clear();
        inTable = false;
        // fall-through to process current line normally
      }

      // Horizontal rule
      if (RegExp(r'^\s*([-*_])\s*\1\s*\1[\-\*_\s]*$').hasMatch(line)) {
        _gutter(_hr());
        continue;
      }

      // Headings #..######
      final h = RegExp(r'^(\s{0,3})(#{1,6})\s+(.*)$').firstMatch(line);
      if (h != null) {
        final level = h.group(2)!.length;
        final text = h.group(3)!.trim();
        _gutter(_heading(text, level));
        continue;
      }

      // Blockquote
      final bq = RegExp(r'^\s*>\s?(.*)$').firstMatch(line);
      if (bq != null) {
        final text = bq.group(1) ?? '';
        _gutter(_blockquote(_inline(text)));
        continue;
      }

      // Task list: - [ ] item / - [x] item
      final task = RegExp(r'^(\s*)[-*+]\s+\[( |x|X)\]\s+(.*)$').firstMatch(line);
      if (task != null) {
        final indent = task.group(1) ?? '';
        final checked = (task.group(2) ?? ' ').toLowerCase() == 'x';
        final text = task.group(3) ?? '';
        _gutter(_task(indent.length, checked, _inline(text)));
        continue;
      }

      // Ordered list
      final ol = RegExp(r'^(\s*)(\d+)[\.)]\s+(.*)$').firstMatch(line);
      if (ol != null) {
        final indent = ol.group(1)!;
        final num = ol.group(2)!;
        final text = ol.group(3)!;
        _gutter(_olist(indent.length, num, _inline(text)));
        continue;
      }

      // Unordered list
      final ul = RegExp(r'^(\s*)[\-*+]\s+(.*)$').firstMatch(line);
      if (ul != null) {
        final indent = ul.group(1)!;
        final text = ul.group(2)!;
        _gutter(_ulist(indent.length, _inline(text)));
        continue;
      }

      // Plain paragraph / empty line
      _gutter(_inline(line));
    }

    // Flush table at EOF
    if (inTable && tableLines.isNotEmpty) {
      for (final tl in _renderTableBlock(tableLines)) {
        _gutter(tl);
      }
    }

    if (style.showBorder) {
      final bottom = FrameRenderer.bottomLine(label, theme);
      stdout.writeln(bottom);
    }
  }

  void _gutter(String content) {
    final s = theme.style;
    if (content.trim().isEmpty) {
      stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset}');
      return;
    }
    final out = color ? content : _stripAnsi(content);
    stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset} $out');
  }

  String _heading(String text, int level) {
    final t = text.trim();
    final c = switch (level) {
      1 => '${theme.selection}${theme.bold}',
      2 => '${theme.accent}${theme.bold}',
      3 => '${theme.highlight}${theme.bold}',
      4 => '${theme.info}${theme.bold}',
      5 => '${theme.warn}${theme.bold}',
      _ => '${theme.gray}${theme.bold}',
    };
    final icon = switch (level) {
      1 => '◆',
      2 => '◈',
      3 => '▸',
      4 => '▹',
      5 => '•',
      _ => '·',
    };
    final header = '$c$icon $t${theme.reset}';
    if (level <= 2) {
      final underline = (level == 1) ? '━' : '─';
      final line = '${theme.gray}${underline * (t.length + 2)}${theme.reset}';
      return '$header\n${theme.gray}$line${theme.reset}';
    }
    return header;
  }

  String _blockquote(String text) {
    return '${theme.dim}❯${theme.reset} $text';
  }

  String _olist(int indentSpaces, String number, String text) {
    final indent = ' ' * indentSpaces;
    return '$indent${theme.accent}$number.${theme.reset} $text';
  }

  String _ulist(int indentSpaces, String text) {
    final indent = ' ' * indentSpaces;
    final bullet = switch ((indentSpaces ~/ 2) % 3) {
      0 => '•',
      1 => '◦',
      _ => '▹',
    };
    final color = ((indentSpaces ~/ 2) % 2 == 0) ? theme.accent : theme.highlight;
    return '$indent$color$bullet${theme.reset} $text';
  }

  String _hr() {
    return '${theme.gray}${'─' * 30}${theme.reset}';
  }

  String _codeFenceTop(String? lang) {
    final label = (lang == null || lang.isEmpty) ? 'code' : lang;
    return '${theme.dim}┌${'─' * 2}${theme.reset} ${theme.selection}${theme.bold}$label${theme.reset}';
  }

  String _codeFenceBottom() {
    return '${theme.dim}└${'─' * 8}${theme.reset}';
  }

  String _renderCodeLine(String line) {
    if (line.trim().isEmpty) return '${theme.dim}│${theme.reset}';
    final dim = theme.dim;
    final sel = theme.selection;
    final hi = theme.highlight;
    var out = line;
    // Strings
    out = out.replaceAllMapped(RegExp(r'"[^"]*"'), (m) => '$hi${m[0]}${theme.reset}');
    out = out.replaceAllMapped(RegExp(r"'[^']*'"), (m) => '$hi${m[0]}${theme.reset}');
    // Numbers
    out = out.replaceAllMapped(RegExp(r'\b\d+(?:\.\d+)?\b'), (m) => '$sel${m[0]}${theme.reset}');
    // Punctuation (light dim)
    out = out.replaceAllMapped(RegExp(r'[\{\}\[\]\(\)\,\;\:]'), (m) => '$dim${m[0]}${theme.reset}');
    return '${theme.dim}│${theme.reset} $out';
  }

  String _inline(String text) {
    var out = text;

    // Inline code `code`
    out = out.replaceAllMapped(
        RegExp(r'`([^`]+)`'), (m) => '${theme.selection}${theme.bold}${m[1]}${theme.reset}');

    // Bold **text** or __text__
    out = out.replaceAllMapped(
        RegExp(r'\*\*([^*]+)\*\*'), (m) => '${theme.bold}${m[1]}${theme.reset}');
    out = out.replaceAllMapped(
        RegExp(r'__([^_]+)__'), (m) => '${theme.bold}${m[1]}${theme.reset}');

    // Italic *text* or _text_
    out = out.replaceAllMapped(
        RegExp(r'\*([^*]+)\*'), (m) => '${theme.dim}${m[1]}${theme.reset}');
    out = out.replaceAllMapped(
        RegExp(r'_([^_]+)_'), (m) => '${theme.dim}${m[1]}${theme.reset}');

    // Links [text](url)
    out = out.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\(([^\)]+)\)'),
        (m) => '${theme.accent}${theme.bold}${m[1]}${theme.reset} ${theme.gray}⟨${m[2]}⟩${theme.reset}');

    return out;
  }

  String _task(int indentSpaces, bool checked, String text) {
    final indent = ' ' * indentSpaces;
    final sym = checked ? theme.style.checkboxOnSymbol : theme.style.checkboxOffSymbol;
    final col = checked ? theme.checkboxOn : theme.checkboxOff;
    final t = checked ? '${theme.dim}$text${theme.reset}' : text;
    return '$indent$col$sym${theme.reset} $t';
  }

  bool _looksLikeTableRow(String line) {
    return line.contains('|') && !line.trim().startsWith('```');
  }

  bool _isTableSeparator(String line) {
    final l = line.trim();
    if (!l.contains('|')) return false;
    return RegExp(r'^\|?\s*:?[-]+:?\s*(\|\s*:?[-]+:?\s*)+\|?$').hasMatch(l);
  }

  List<String> _renderTableBlock(List<String> lines) {
    if (lines.isEmpty) return const [];

    // Split into rows of cells (trim outer pipes)
    List<List<String>> rows = lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) {
          var t = l.trim();
          if (t.startsWith('|')) t = t.substring(1);
          if (t.endsWith('|')) t = t.substring(0, t.length - 1);
          return t.split('|').map((c) => c.trim()).toList();
        })
        .toList();

    if (rows.length < 2) {
      // Not a real table, just echo
      return lines.map((l) => _inline(l)).toList();
    }

    // Alignment from separator row (second row)
    final sep = rows[1];
    final colCount = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    List<String> align = List.filled(colCount, 'left');
    for (var i = 0; i < colCount; i++) {
      final cell = (i < sep.length ? sep[i] : '').trim();
      final starts = cell.startsWith(':');
      final ends = cell.endsWith(':');
      if (starts && ends) {
        align[i] = 'center';
      } else if (ends) align[i] = 'right';
      else align[i] = 'left';
    }

    // Compute widths from header + body (excluding separator row)
    final contentRows = <List<String>>[rows[0], ...rows.skip(2)];
    final widths = List<int>.filled(colCount, 0);
    for (final r in contentRows) {
      for (var i = 0; i < colCount; i++) {
        final cell = i < r.length ? _inline(r[i]) : '';
        final w = _visibleLength(cell);
        if (w > widths[i]) widths[i] = w;
      }
    }

    String pad(String txt, int w, String a) {
      final visible = _visibleLength(txt);
      final needed = (w - visible).clamp(0, 1000);
      if (a == 'right') return '${' ' * needed}$txt';
      if (a == 'center') {
        final left = needed ~/ 2;
        final right = needed - left;
        return '${' ' * left}$txt${' ' * right}';
      }
      return '$txt${' ' * needed}';
    }

    String sepLine() {
      final parts = <String>[];
      for (var i = 0; i < colCount; i++) {
        parts.add('${theme.gray}${'─' * widths[i]}${theme.reset}');
      }
      return parts.join(' ${theme.gray}┼${theme.reset} ');
    }

    final out = <String>[];
    // Header
    final header = <String>[];
    for (var i = 0; i < colCount; i++) {
      final cell = i < rows[0].length ? _inline(rows[0][i]) : '';
      header.add('${theme.bold}${pad(cell, widths[i], align[i])}${theme.reset}');
    }
    out.add(header.join(' ${theme.gray}│${theme.reset} '));
    out.add(sepLine());
    // Body
    for (final r in rows.skip(2)) {
      final cells = <String>[];
      for (var i = 0; i < colCount; i++) {
        final cell = i < r.length ? _inline(r[i]) : '';
        cells.add(pad(cell, widths[i], align[i]));
      }
      out.add(cells.join(' ${theme.gray}│${theme.reset} '));
    }
    return out;
  }

  int _visibleLength(String s) {
    return _stripAnsi(s).runes.length;
  }
}

/// Convenience function mirroring the widget API name.
void markdownViewer(
  String markdown, {
  PromptTheme theme = const PromptTheme(),
  String? title,
  bool color = true,
}) {
  MarkdownViewer(
    markdown,
    theme: theme,
    title: title,
    color: color,
  ).show();
}

String _stripAnsi(String input) {
  final ansi = RegExp(r'\x1B\[[0-9;]*m');
  return input.replaceAll(ansi, '');
}


