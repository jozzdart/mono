import 'package:intl/intl.dart';
import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

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

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // ←/→ switch field
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              fieldIndex = (fieldIndex - 1).clamp(0, 2);
              return KeyActionResult.handled;
            },
            hintLabel: '←/→',
            hintDescription: 'switch',
          ),
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              fieldIndex = (fieldIndex + 1).clamp(0, 2);
              return KeyActionResult.handled;
            },
          ),
          // ↑/↓ adjust field
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              adjustField(1);
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓',
            hintDescription: 'adjust',
          ),
          KeyBinding.single(
            KeyEventType.arrowDown,
            (event) {
              adjustField(-1);
              return KeyActionResult.handled;
            },
          ),
          // Ctrl+E - today
          KeyBinding.single(
            KeyEventType.cnrlE,
            (event) {
              selected = DateTime.now();
              return KeyActionResult.handled;
            },
            hintLabel: 'Ctrl+E',
            hintDescription: 'today',
          ),
        ]) +
        KeyBindings.confirm() +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final title = '$label — Choose Date';
      final widgetFrame = WidgetFrame(
        title: '  $title  ',
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.bullets,
      );

      widgetFrame.render(out, (ctx) {
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
        ctx.gutterLine('$leftPad${fields.join('   ')}');

        // Preview
        final formatted =
            DateFormat('EEE, d MMM yyyy').format(selected).padLeft(10);
        ctx.gutterLine(
            '$leftPad${theme.gray}Preview:${theme.reset} ${theme.accent}$formatted${theme.reset}');
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return (cancelled || result == PromptResult.cancelled) ? null : selected;
  }
}
