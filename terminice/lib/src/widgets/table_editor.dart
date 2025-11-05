import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

/// Interactive CSV-like grid editor.
///
/// - Arrow keys move the selection
/// - Enter to edit a cell; Enter again to commit (or type directly to start editing)
/// - Esc cancels editing (or exits without saving if not editing)
/// - Tab moves to the next cell
/// - 'a' adds a row below; 'd' deletes the current row
/// - Enter (when not editing) confirms and returns edited data
///
/// Styling aligns with ThemeDemo via FrameRenderer, themed borders, zebra rows,
/// and accent/bold header.
class TableEditor {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final PromptTheme theme;
  final bool zebraStripes;

  TableEditor(
    this.title, {
    required this.columns,
    required this.rows,
    this.theme = PromptTheme.dark,
    this.zebraStripes = true,
  }) : assert(columns.isNotEmpty, 'columns must not be empty');

  /// Runs the editor and returns the possibly edited data.
  /// If cancelled, returns the original [rows] data.
  List<List<String>> run() {
    // Work on a deep copy to avoid mutating input until confirmed.
    final original = rows.map((r) => List<String>.from(r)).toList();
    final data = rows.map((r) => List<String>.from(r)).toList();

    // Selection and editing state
    int selectedRow = data.isEmpty ? 0 : 0;
    int selectedCol = 0;
    bool editing = false;
    String editBuffer = '';

    // Ensure at least one empty row to allow editing
    if (data.isEmpty) {
      data.add(List<String>.filled(columns.length, ''));
    }

    final style = theme.style;

    // Precompute helpful glyphs
    final String colSep = '${theme.gray}${style.borderVertical}${theme.reset}';

    // Terminal setup
    final term = Terminal.enterRaw();

    void cleanup() {
      term.restore();
      stdout.write('\x1B[?25h');
    }

    List<int> computeWidths() {
      final widths = List<int>.generate(columns.length, (i) => _visible(columns[i]).length);
      for (final row in data) {
        for (var i = 0; i < columns.length; i++) {
          final cell = (i < row.length) ? row[i] : '';
          widths[i] = max(widths[i], _visible(cell).length);
        }
      }
      // Pad a bit; clamp to a reasonable max to limit overly wide cells.
      for (var i = 0; i < widths.length; i++) {
        widths[i] = widths[i].clamp(3, 40) + 2; // padding space
      }
      return widths;
    }

    String renderCell(String text, int width, bool isSelected, bool isEditing) {
      // Truncate with ellipsis if needed
      final maxText = max(0, width - 1);
      String visible = _visible(text);
      if (visible.length > maxText) {
        visible = '${visible.substring(0, max(0, maxText - 1))}…';
      }

      if (isEditing) {
        // Show a thin cursor indicator at the end while editing
        final cursor = '${theme.accent}|${theme.reset}';
        final base = visible + cursor;
        final padded = base.padRight(width);
        if (style.useInverseHighlight) return '${theme.inverse}$padded${theme.reset}';
        return '${theme.selection}$padded${theme.reset}';
      }

      final padded = visible.padRight(width);
      if (isSelected) {
        if (style.useInverseHighlight) return '${theme.inverse}$padded${theme.reset}';
        return '${theme.selection}$padded${theme.reset}';
      }
      return padded;
    }

    void ensureInBounds() {
      if (selectedRow < 0) selectedRow = 0;
      if (selectedRow >= data.length) selectedRow = data.length - 1;
      if (selectedCol < 0) selectedCol = 0;
      if (selectedCol >= columns.length) selectedCol = columns.length - 1;
    }

    void startEditing({bool overwrite = true, String? firstChar}) {
      final row = data[selectedRow];
      final current = (selectedCol < row.length) ? row[selectedCol] : '';
      if (overwrite) {
        editBuffer = firstChar ?? current;
      } else {
        editBuffer = current + (firstChar ?? '');
      }
      editing = true;
    }

    void commitEdit() {
      if (!editing) return;
      final row = data[selectedRow];
      if (selectedCol >= row.length) {
        // Expand row if somehow shorter
        row.addAll(List<String>.filled(selectedCol - row.length + 1, ''));
      }
      row[selectedCol] = editBuffer;
      editing = false;
      editBuffer = '';
    }

    void cancelEdit() {
      editing = false;
      editBuffer = '';
    }

    void addRowBelow() {
      final newRow = List<String>.filled(columns.length, '');
      data.insert(selectedRow + 1, newRow);
      selectedRow += 1;
      selectedCol = min(selectedCol, columns.length - 1);
    }

    void deleteRow() {
      if (data.length <= 1) return;
      data.removeAt(selectedRow);
      if (selectedRow >= data.length) selectedRow = data.length - 1;
    }

    void render() {
      Terminal.clearAndHome();

      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      stdout.writeln('${theme.bold}$top${theme.reset}');

      final widths = computeWidths();

      // Header
      final header = StringBuffer();
      header.write('${theme.gray}${style.borderVertical}${theme.reset} ');
      for (var i = 0; i < columns.length; i++) {
        if (i > 0) header.write(' $colSep ');
        header.write('${theme.bold}${theme.accent}');
        final colName = columns[i];
        final colText = colName.length > widths[i]
            ? '${colName.substring(0, max(0, widths[i] - 1))}…'
            : colName;
        header.write(colText.padRight(widths[i]));
        header.write(theme.reset);
      }
      stdout.writeln(header.toString());

      // Connector under header sized to the table content width
      final tableWidth = 2 + // left border + space
          widths.fold<int>(0, (sum, w) => sum + w) +
          (columns.length - 1) * 3; // separators ' │ '
      stdout.writeln(
          '${theme.gray}${style.borderConnector}${'─' * tableWidth}${theme.reset}');

      // Rows
      for (var r = 0; r < data.length; r++) {
        final row = data[r];
        final rowBuf = StringBuffer();
        rowBuf.write('${theme.gray}${style.borderVertical}${theme.reset} ');

        final stripe = zebraStripes && (r % 2 == 1);
        final prefix = stripe ? theme.dim : '';
        final suffix = stripe ? theme.reset : '';

        for (var c = 0; c < columns.length; c++) {
          if (c > 0) rowBuf.write(' $colSep ');
          final cell = (c < row.length) ? row[c] : '';
          final isSel = r == selectedRow && c == selectedCol;
          final isEdit = isSel && editing;
          final rendered = renderCell(isEdit ? editBuffer : cell, widths[c], isSel, isEdit);
          rowBuf.write(prefix);
          rowBuf.write(rendered);
          rowBuf.write(suffix);
        }
        stdout.writeln(rowBuf.toString());
      }

      if (style.showBorder) {
        stdout.writeln(frame.bottom());
      }

      // Status line
      final status = '${theme.info}Row ${selectedRow + 1}/${data.length} · Col ${selectedCol + 1}/${columns.length}${theme.reset}';
      stdout.writeln(status);

      // Hints
      final rowsHints = <List<String>>[
        [Hints.key('↑/↓/←/→', theme), 'move'],
        [Hints.key('Enter', theme), editing ? 'commit edit' : 'edit / finish'],
        [Hints.key('Tab', theme), 'next cell'],
        [Hints.key('a', theme), 'add row below'],
        [Hints.key('d', theme), 'delete row'],
        [Hints.key('Esc', theme), editing ? 'cancel edit' : 'cancel editor'],
        [Hints.key('Type', theme), 'start editing'],
      ];
      stdout.writeln(Hints.grid(rowsHints, theme));
      Terminal.hideCursor();
    }

    render();

    bool cancelled = false;

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (!editing) {
          if (ev.type == KeyEventType.enter) {
            // Finish editor
            break;
          }
          if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
            cancelled = true;
            break;
          }
          if (ev.type == KeyEventType.arrowUp) {
            selectedRow = (selectedRow - 1 + data.length) % data.length;
          } else if (ev.type == KeyEventType.arrowDown) {
            selectedRow = (selectedRow + 1) % data.length;
          } else if (ev.type == KeyEventType.arrowLeft) {
            selectedCol = (selectedCol - 1 + columns.length) % columns.length;
          } else if (ev.type == KeyEventType.arrowRight || ev.type == KeyEventType.tab) {
            selectedCol = (selectedCol + 1) % columns.length;
            if (selectedCol == 0) {
              selectedRow = (selectedRow + 1) % data.length;
            }
          } else if (ev.type == KeyEventType.char) {
            final ch = ev.char ?? '';
            if (ch == 'a') {
              addRowBelow();
            } else if (ch == 'd') {
              deleteRow();
            } else if (ch == 'e') {
              startEditing(overwrite: true);
            } else if (ch == 's') {
              // Save/finish
              break;
            } else {
              // Begin editing with first typed char overwriting existing content
              startEditing(overwrite: true, firstChar: ch);
            }
          }
        } else {
          // Editing mode
          if (ev.type == KeyEventType.enter) {
            commitEdit();
            // Move to next cell for quick data entry
            selectedCol = (selectedCol + 1) % columns.length;
            if (selectedCol == 0) {
              selectedRow = (selectedRow + 1) % data.length;
            }
          } else if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
            cancelEdit();
          } else if (ev.type == KeyEventType.backspace) {
            if (editBuffer.isNotEmpty) {
              editBuffer = editBuffer.substring(0, editBuffer.length - 1);
            }
          } else if (ev.type == KeyEventType.tab) {
            commitEdit();
            selectedCol = (selectedCol + 1) % columns.length;
            if (selectedCol == 0) {
              selectedRow = (selectedRow + 1) % data.length;
            }
          } else if (ev.type == KeyEventType.char) {
            editBuffer += ev.char!;
          } else if (ev.type == KeyEventType.arrowLeft) {
            // Optional: left/right within cell could be supported; for simplicity, move cell
            commitEdit();
            selectedCol = (selectedCol - 1 + columns.length) % columns.length;
          } else if (ev.type == KeyEventType.arrowRight) {
            commitEdit();
            selectedCol = (selectedCol + 1) % columns.length;
          } else if (ev.type == KeyEventType.arrowUp) {
            commitEdit();
            selectedRow = (selectedRow - 1 + data.length) % data.length;
          } else if (ev.type == KeyEventType.arrowDown) {
            commitEdit();
            selectedRow = (selectedRow + 1) % data.length;
          }
        }

        ensureInBounds();
        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    Terminal.showCursor();

    if (cancelled) return original;
    // Commit pending edit if any when finishing
    if (editing) {
      commitEdit();
    }
    return data;
  }
}

String _visible(String s) {
  // Remove ANSI escape sequences like \x1B[...m
  return s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
}
