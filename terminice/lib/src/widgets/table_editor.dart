import 'dart:math';

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/table_renderer.dart';
import '../system/text_input_buffer.dart';
import '../system/widget_frame.dart';

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
    // Use centralized text input for cell editing
    final editBuffer = TextInputBuffer();
    bool cancelled = false;

    // Ensure at least one empty row to allow editing
    if (data.isEmpty) {
      data.add(List<String>.filled(columns.length, ''));
    }

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
        editBuffer.setText(firstChar ?? current);
      } else {
        editBuffer.setText(current + (firstChar ?? ''));
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
      row[selectedCol] = editBuffer.text;
      editing = false;
      editBuffer.clear();
    }

    void cancelEdit() {
      editing = false;
      editBuffer.clear();
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

    void moveToNextCell() {
      selectedCol = (selectedCol + 1) % columns.length;
      if (selectedCol == 0) {
        selectedRow = (selectedRow + 1) % data.length;
      }
    }

    void render(RenderOutput out) {
      final widgetFrame = WidgetFrame(
        title: title,
        theme: theme,
        hintStyle: HintStyle.none, // Custom hints based on editing state
      );

      widgetFrame.render(out, (ctx) {
        // Recompute widths (data may have changed)
        renderer.computeWidths(data);

        // Header and connector
        ctx.line(renderer.headerLine());
        ctx.line(renderer.connectorLine());

        // Data rows with selection
        for (var r = 0; r < data.length; r++) {
          final row = data[r];
          final isSelectedRow = r == selectedRow;

          if (isSelectedRow) {
            ctx.line(renderer.selectableRowLine(
              row,
              index: r,
              selectedColumn: selectedCol,
              isEditing: editing,
              editBuffer: editBuffer.text,
            ));
          } else {
            ctx.line(renderer.rowLine(row, index: r));
          }
        }
      });

      // Status line
      final status =
          '${theme.info}Row ${selectedRow + 1}/${data.length} · Col ${selectedCol + 1}/${columns.length}${theme.reset}';
      out.writeln(status);

      // Hints - dynamic based on editing state
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

    // Use KeyBindings for declarative key handling
    // Note: This widget has conditional behavior based on 'editing' state
    final bindings = KeyBindings([
          // Enter: commit edit (editing) or finish editor (not editing)
          KeyBinding.single(
            KeyEventType.enter,
            (event) {
              if (!editing) {
                return KeyActionResult.confirmed;
              } else {
                commitEdit();
                moveToNextCell();
              }
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
          // Esc/Ctrl+C: cancel edit (editing) or cancel editor (not editing)
          KeyBinding.multi(
            {KeyEventType.esc, KeyEventType.ctrlC},
            (event) {
              if (!editing) {
                cancelled = true;
                return KeyActionResult.cancelled;
              } else {
                cancelEdit();
              }
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
          // Arrow Up
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              if (editing) commitEdit();
              selectedRow = (selectedRow - 1 + data.length) % data.length;
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
          // Arrow Down
          KeyBinding.single(
            KeyEventType.arrowDown,
            (event) {
              if (editing) commitEdit();
              selectedRow = (selectedRow + 1) % data.length;
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
          // Arrow Left
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              if (editing) commitEdit();
              selectedCol = (selectedCol - 1 + columns.length) % columns.length;
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
          // Arrow Right / Tab
          KeyBinding.multi(
            {KeyEventType.arrowRight, KeyEventType.tab},
            (event) {
              if (editing) commitEdit();
              moveToNextCell();
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
          // Character input
          KeyBinding.char(
            (c) => true,
            (event) {
              final ch = event.char ?? '';
              if (!editing) {
                if (ch == 'a') {
                  addRowBelow();
                } else if (ch == 'd') {
                  deleteRow();
                } else if (ch == 'e') {
                  startEditing(overwrite: true);
                } else if (ch == 's') {
                  return KeyActionResult.confirmed;
                } else {
                  // Begin editing with first typed char overwriting existing content
                  startEditing(overwrite: true, firstChar: ch);
                }
              } else {
                // Text input - handled by centralized TextInputBuffer
                editBuffer.handleKey(event);
              }
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
          // Backspace (only in editing mode)
          KeyBinding.single(
            KeyEventType.backspace,
            (event) {
              if (editing) {
                editBuffer.handleKey(event);
              }
              ensureInBounds();
              return KeyActionResult.handled;
            },
          ),
        ]);

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    if (cancelled) return original;
    // Commit pending edit if any when finishing
    if (editing) {
      commitEdit();
    }
    return data;
  }
}
