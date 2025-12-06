import 'package:intl/intl.dart';
import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';

/// ─────────────────────────────────────────────────────────────
/// DateFieldsPrompt – elegant multi-field date selector
/// ─────────────────────────────────────────────────────────────
///
/// Controls:
/// - ←/→ switch between fields
/// - ↑/↓ adjust current field
/// - [Ctrl+E] jump to today
/// - [Enter] confirm
/// - [Esc] cancel
class DateFieldsPrompt {
  final String label;
  final PromptTheme theme;
  final DateTime initial;

  DateFieldsPrompt({
    required this.label,
    this.theme = PromptTheme.dark,
    DateTime? initial,
  }) : initial = initial ?? DateTime.now();

  DateTime? run() {
    final style = theme.style;
    const innerPadding = 4;

    DateTime selected = DateTime(initial.year, initial.month, initial.day);
    int fieldIndex = 0; // 0=day, 1=month, 2=year
    bool cancelled = false;

    void adjustField(int delta) {
      switch (fieldIndex) {
        case 0:
          selected = selected.add(Duration(days: delta));
          break;
        case 1:
          selected = DateTime(
            selected.year,
            selected.month + delta,
            selected.day,
          );
          break;
        case 2:
          selected = DateTime(
            selected.year + delta,
            selected.month,
            selected.day,
          );
          break;
      }
    }

    void render(RenderOutput out) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);

      final title = '$label — Choose Date';
      final paddedTitle = '  $title  ';
      if (style.showBorder) {
        final frame = FramedLayout(paddedTitle, theme: theme);
        out.writeln(frame.top());
      } else {
        out.writeln('${theme.accent}$paddedTitle${theme.reset}');
      }

      final leftPad = ' ' * innerPadding;
      final monthName = DateFormat('MMMM').format(selected);

      // Field highlighting
      String fmt(String label, String value, bool active) {
        if (active) {
          return '${theme.inverse} $label: $value ${theme.reset}';
        } else {
          return '${theme.dim}$label:${theme.reset} $value';
        }
      }

      // Fields
      final fields = [
        fmt('Day', selected.day.toString().padLeft(2), fieldIndex == 0),
        fmt('Month', monthName, fieldIndex == 1),
        fmt('Year', selected.year.toString(), fieldIndex == 2),
      ];

      // Layout
      out.writeln('${lb.gutter()}$leftPad${fields.join('   ')}');

      // Preview
      final formatted =
          DateFormat('EEE, d MMM yyyy').format(selected).padLeft(10);
      out.writeln(
          '${lb.gutter()}$leftPad${theme.gray}Preview:${theme.reset} ${theme.accent}$formatted${theme.reset}');

      // Footer
      if (style.showBorder) {
        final frame = FramedLayout(title, theme: theme);
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.bullets([
        Hints.hint('←/→', 'switch', theme),
        Hints.hint('↑/↓', 'adjust', theme),
        Hints.hint('Ctrl+E', 'today', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.enter) return PromptResult.confirmed;

        if (ev.type == KeyEventType.cnrlE) {
          selected = DateTime.now();
        }

        // ←/→ switch field
        if (ev.type == KeyEventType.arrowLeft) {
          fieldIndex = (fieldIndex - 1).clamp(0, 2);
        } else if (ev.type == KeyEventType.arrowRight) {
          fieldIndex = (fieldIndex + 1).clamp(0, 2);
        }

        // ↑/↓ adjust field
        else if (ev.type == KeyEventType.arrowUp) {
          adjustField(1);
        } else if (ev.type == KeyEventType.arrowDown) {
          adjustField(-1);
        }

        return null;
      },
    );

    return (cancelled || result == PromptResult.cancelled) ? null : selected;
  }
}
