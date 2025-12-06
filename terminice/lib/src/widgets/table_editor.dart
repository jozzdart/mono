import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
import '../system/table_renderer.dart';

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
    bool cancelled = false;

    // Ensure at least one empty row to allow editing
    if (data.isEmpty) {
      data.add(List<String>.filled(columns.length, ''));
    }

    final style = theme.style;

    // Create table renderer
    final renderer = TableRenderer.fromHeaders(
      columns,
      theme: theme,
      zebraStripes: zebraStripes,
      cellPadding: 2, // Extra padding for editor cells
    );

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

    void render(RenderOutput out) {
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln('${theme.bold}$top${theme.reset}');

      // Recompute widths (data may have changed)
      renderer.computeWidths(data);

      // Header and connector
      out.writeln(renderer.headerLine());
      out.writeln(renderer.connectorLine());

      // Data rows with selection
      for (var r = 0; r < data.length; r++) {
        final row = data[r];
        final isSelectedRow = r == selectedRow;

        if (isSelectedRow) {
          out.writeln(renderer.selectableRowLine(
            row,
            index: r,
            selectedColumn: selectedCol,
            isEditing: editing,
            editBuffer: editBuffer,
          ));
        } else {
          out.writeln(renderer.rowLine(row, index: r));
        }
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Status line
      final status =
          '${theme.info}Row ${selectedRow + 1}/${data.length} · Col ${selectedCol + 1}/${columns.length}${theme.reset}';
      out.writeln(status);

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
      out.writeln(Hints.grid(rowsHints, theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (!editing) {
          if (ev.type == KeyEventType.enter) {
            // Finish editor
            return PromptResult.confirmed;
          }
          if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
            cancelled = true;
            return PromptResult.cancelled;
          }
          if (ev.type == KeyEventType.arrowUp) {
            selectedRow = (selectedRow - 1 + data.length) % data.length;
          } else if (ev.type == KeyEventType.arrowDown) {
            selectedRow = (selectedRow + 1) % data.length;
          } else if (ev.type == KeyEventType.arrowLeft) {
            selectedCol = (selectedCol - 1 + columns.length) % columns.length;
          } else if (ev.type == KeyEventType.arrowRight ||
              ev.type == KeyEventType.tab) {
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
              return PromptResult.confirmed;
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
          } else if (ev.type == KeyEventType.esc ||
              ev.type == KeyEventType.ctrlC) {
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
        return null;
      },
    );

    if (cancelled) return original;
    // Commit pending edit if any when finishing
    if (editing) {
      commitEdit();
    }
    return data;
  }
}
