import 'dart:math' as math;

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/text_utils.dart' as text;

/// LaunchPad – grid of big icons/buttons for actions.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/highlight colors and inverse selection
class LaunchPad {
  final String title;
  final List<LaunchAction> actions;
  final PromptTheme theme;

  /// Fixed number of columns. If <= 0, columns are computed from terminal width.
  final int columns;

  /// Width of each tile (content width, not counting separators).
  /// If <= 0, computed from content.
  final int cellWidth;

  /// Number of content lines per tile. Minimum 3.
  /// Default layout:
  ///  - icon
  ///  - (optional) description or spacer
  ///  - label
  final int tileHeight;

  /// When true, shows a single-line description beneath the icon if provided.
  final bool showDescriptions;

  const LaunchPad(
    this.title,
    this.actions, {
    this.theme = const PromptTheme(),
    this.columns = 0,
    this.cellWidth = 0,
    this.tileHeight = 4,
    this.showDescriptions = true,
  });

  /// Runs the launch pad UI. Returns the selected action or null if cancelled.
  LaunchAction? run({bool executeOnEnter = false}) {
    if (actions.isEmpty) return null;
    final style = theme.style;

    // Layout
    final int computedCellWidth = _computeCellWidth();
    final int cols = _computeColumns(computedCellWidth);
    final int rows = (actions.length + cols - 1) ~/ cols;
    final String colSep = ' ${theme.gray}${style.borderVertical}${theme.reset} ';

    // State
    int selected = 0;
    LaunchAction? result;

    void render(RenderOutput out) {
      // Title
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln('${theme.bold}$top${theme.reset}');

      // Render row-by-row; each tile expands to the same number of lines
      for (int r = 0; r < rows; r++) {
        final start = r * cols;
        final end = math.min(start + cols, actions.length);
        final slice = actions.sublist(start, end);

        final tiles = <List<String>>[];
        for (int i = 0; i < slice.length; i++) {
          final idx = start + i;
          tiles.add(_renderTile(slice[i],
              width: computedCellWidth, height: tileHeight, highlighted: idx == selected));
        }

        // Normalize height across tiles in this row
        final int linesPerTile = tiles
            .map((t) => t.length)
            .fold<int>(0, (a, b) => math.max(a, b));
        for (final t in tiles) {
          while (t.length < linesPerTile) {
            t.add(' '.padRight(computedCellWidth));
          }
        }

        // Print each visual line across the row
        for (int line = 0; line < linesPerTile; line++) {
          final buf = StringBuffer();
          buf.write('${theme.gray}${style.borderVertical}${theme.reset} ');
          for (int i = 0; i < tiles.length; i++) {
            if (i > 0) buf.write(colSep);
            buf.write(tiles[i][line]);
          }
          out.writeln(buf.toString());
        }

        // Connector between rows
        if (r < rows - 1) {
          final connector = StringBuffer();
          connector.write('${theme.gray}${style.borderConnector}${theme.reset}');
          connector.write(
              '${theme.gray}${'─' * _rowContentWidth(tiles.length, computedCellWidth)}${theme.reset}');
          out.writeln(connector.toString());
        }
      }

      // Bottom border line
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints
      out.writeln(Hints.grid([
        [Hints.key('↑/↓/←/→', theme), 'navigate'],
        [Hints.key('Enter', theme), executeOnEnter ? 'launch' : 'select'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    int moveUp(int idx) {
      final col = idx % cols;
      var row = idx ~/ cols;
      for (int i = 0; i < rows; i++) {
        row = (row - 1 + rows) % rows;
        final cand = row * cols + col;
        if (cand < actions.length) return cand;
      }
      return idx;
    }

    int moveDown(int idx) {
      final col = idx % cols;
      var row = idx ~/ cols;
      for (int i = 0; i < rows; i++) {
        row = (row + 1) % rows;
        final cand = row * cols + col;
        if (cand < actions.length) return cand;
      }
      return idx;
    }

    int moveLeft(int idx) {
      if (idx == 0) return actions.length - 1;
      return idx - 1;
    }

    int moveRight(int idx) {
      if (idx == actions.length - 1) return 0;
      return idx + 1;
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.enter) {
          final chosen = actions[selected];
          if (executeOnEnter && chosen.onActivate != null) {
            result = chosen;
            return PromptResult.confirmed;
          }
          result = chosen;
          return PromptResult.confirmed;
        }
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.arrowUp) {
          selected = moveUp(selected);
        } else if (ev.type == KeyEventType.arrowDown) {
          selected = moveDown(selected);
        } else if (ev.type == KeyEventType.arrowLeft) {
          selected = moveLeft(selected);
        } else if (ev.type == KeyEventType.arrowRight) {
          selected = moveRight(selected);
        }

        return null;
      },
    );

    // Execute after cleanup if needed
    if (result != null && executeOnEnter && result!.onActivate != null) {
      result!.onActivate!.call();
    }

    return result;
  }

  int _computeColumns(int width) {
    if (columns > 0) return columns;
    final termWidth = TerminalInfo.columns;
    // Left gutter is "│ " (2). Separator is " │ " (3).
    const leftPrefix = 2;
    const sepWidth = 3;
    final unit = width + sepWidth;
    final colsByWidth = math.max(1, ((termWidth - leftPrefix) + sepWidth) ~/ unit);
    // Aim for a balanced grid roughly sqrt(n)
    final desired = math.max(2, math.min(actions.length, math.sqrt(actions.length).ceil()));
    return math.min(colsByWidth, desired);
  }

  int _computeCellWidth() {
    if (cellWidth > 0) return cellWidth;
    final maxLabel = actions.fold<int>(0, (w, a) => math.max(w, text.visibleLength(a.label)));
    final maxDesc = showDescriptions
        ? actions.fold<int>(0, (w, a) => math.max(w, text.visibleLength(a.description ?? '')))
        : 0;
    final base = math.max(maxLabel, maxDesc);
    return base.clamp(12, 26) + 6; // padding for icon and breathing room
  }

  int _rowContentWidth(int cellsInRow, int width) {
    if (cellsInRow <= 0) return 0;
    // width = left space (1 after gutter) + cells*width + (cells-1)*3
    return 1 + (cellsInRow * width) + (math.max(0, cellsInRow - 1) * 3);
  }

  List<String> _renderTile(LaunchAction action,
      {required int width, required int height, required bool highlighted}) {
    final int h = math.max(3, height);

    // Lines: top stripe, icon, optional description/spacer(s), label, bottom stripe
    final lines = <String>[];

    // Top accent stripe for oomph
    lines.add(_tileStripe(theme, width));

    // Icon line (centered, ASCII-only)
    final iconAscii = _asciiIconOrInitial(action.icon, action.label);
    final icon = _center('${theme.highlight}$iconAscii${theme.reset}', width);

    // Description or spacer
    String middle;
    if (showDescriptions && (action.description != null) && action.description!.trim().isNotEmpty) {
      final descVisible = _clip(action.description!, width - 2);
      middle = _center('${theme.dim}$descVisible${theme.reset}', width);
    } else {
      middle = ' '.padRight(width);
    }

    // Label line (accent + bold)
    final labelVisible = _clip(action.label, width - 2);
    final labelFramed = '[ ${theme.bold}${theme.accent}$labelVisible${theme.reset} ]';
    final label = _center(labelFramed, width);

    lines.add(icon);
    lines.add(middle);
    lines.add(label);

    // Add extra spacers if tile height > 3
    while (lines.length < h) {
      lines.insert(1, ' '.padRight(width));
    }

    // Bottom subtle stripe
    lines.add(_tileStripe(theme, width, subtle: true));

    if (!highlighted) return lines;

    // Apply highlighted style per line
    final useInverse = theme.style.useInverseHighlight;
    return lines
        .map((l) => useInverse ? '${theme.inverse}$l${theme.reset}' : '${theme.selection}$l${theme.reset}')
        .toList(growable: false);
  }
}

class LaunchAction {
  final String label;
  final String icon;
  final String? description;
  final void Function()? onActivate;

  const LaunchAction(
    this.label, {
    this.icon = '◆',
    this.description,
    this.onActivate,
  });
}

/// Convenience function mirroring the requested API name.
LaunchAction? launchPad(
  String title,
  List<LaunchAction> actions, {
  PromptTheme theme = const PromptTheme(),
  int columns = 0,
  int cellWidth = 0,
  int tileHeight = 3,
  bool showDescriptions = true,
  bool executeOnEnter = false,
}) {
  return LaunchPad(
    title,
    actions,
    theme: theme,
    columns: columns,
    cellWidth: cellWidth,
    tileHeight: tileHeight,
    showDescriptions: showDescriptions,
  ).run(executeOnEnter: executeOnEnter);
}

// Helpers using centralized text_utils
String _clip(String content, int width) {
  final plain = text.stripAnsi(content);
  if (plain.length <= width) return plain;
  if (width <= 0) return '';
  return '${plain.substring(0, math.max(0, width - 1))}…';
}

String _center(String content, int width) {
  final visible = text.stripAnsi(content);
  if (visible.length >= width) return visible.substring(0, width);
  final totalPad = width - visible.length;
  final left = totalPad ~/ 2;
  final right = totalPad - left;
  return (' ' * left) + visible + (' ' * right);
}

String _asciiIconOrInitial(String icon, String label) {
  // keep only ASCII visible characters
  final ascii = icon.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
  if (ascii.isNotEmpty) return ascii;
  // fallback: first letter from label as bracketed initial
  final letter = label.trim().isNotEmpty ? label.trim()[0].toUpperCase() : '?';
  return '[ $letter ]';
}

String _tileStripe(PromptTheme theme, int width, {bool subtle = false}) {
  // Alternating accent/highlight dashes for punchy top stripes; dim for subtle
  final buf = StringBuffer();
  for (int i = 0; i < width; i++) {
    final color = subtle ? theme.dim : (i % 2 == 0 ? theme.accent : theme.highlight);
    buf.write('$color─${theme.reset}');
  }
  return buf.toString();
}
