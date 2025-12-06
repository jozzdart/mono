import 'package:intl/intl.dart';
import '../style/theme.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// ─────────────────────────────────────────────────────────────
/// DatePickerPrompt – aesthetic, padded, responsive CLI calendar
/// ─────────────────────────────────────────────────────────────
///
/// Controls:
/// - ←/→ move one day
/// - ↑/↓ move one week
/// - [W]/[S] move one year forward/back
/// - [Ctrl+E] jump to today
/// - [Enter] confirm
/// - [Esc] cancel
///
/// Config:
/// - [startWeekOnMonday] if false → week starts Sunday
class DatePickerPrompt {
  final String label;
  final PromptTheme theme;
  final DateTime initial;
  final bool allowPast;
  final bool allowFuture;
  final bool startWeekOnMonday;

  DatePickerPrompt({
    required this.label,
    this.theme = PromptTheme.dark,
    DateTime? initial,
    this.allowPast = true,
    this.allowFuture = true,
    this.startWeekOnMonday = true,
  }) : initial = initial ?? DateTime.now();

  DateTime? run() {
    DateTime selected = DateTime(initial.year, initial.month, initial.day);
    DateTime viewMonth = DateTime(selected.year, selected.month);
    bool cancelled = false;

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // ←/→ → move day
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              selected = selected.subtract(const Duration(days: 1));
              viewMonth = DateTime(selected.year, selected.month);
              return KeyActionResult.handled;
            },
            hintLabel: '←/→',
            hintDescription: 'day',
          ),
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              selected = selected.add(const Duration(days: 1));
              viewMonth = DateTime(selected.year, selected.month);
              return KeyActionResult.handled;
            },
          ),
          // ↑/↓ → move week
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              selected = selected.subtract(const Duration(days: 7));
              viewMonth = DateTime(selected.year, selected.month);
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓',
            hintDescription: 'week',
          ),
          KeyBinding.single(
            KeyEventType.arrowDown,
            (event) {
              selected = selected.add(const Duration(days: 7));
              viewMonth = DateTime(selected.year, selected.month);
              return KeyActionResult.handled;
            },
          ),
          // W/S → move year
          KeyBinding.char(
            (c) => c.toLowerCase() == 'w',
            (event) {
              selected =
                  DateTime(selected.year + 1, selected.month, selected.day);
              viewMonth = DateTime(selected.year, selected.month);
              return KeyActionResult.handled;
            },
            hintLabel: 'W/S',
            hintDescription: 'year',
          ),
          KeyBinding.char(
            (c) => c.toLowerCase() == 's',
            (event) {
              selected =
                  DateTime(selected.year - 1, selected.month, selected.day);
              viewMonth = DateTime(selected.year, selected.month);
              return KeyActionResult.handled;
            },
          ),
          // Ctrl+E → today
          KeyBinding.single(
            KeyEventType.cnrlE,
            (event) {
              selected = DateTime.now();
              viewMonth = DateTime(selected.year, selected.month);
              return KeyActionResult.handled;
            },
            hintLabel: 'Ctrl+E',
            hintDescription: 'today',
          ),
        ]) +
        KeyBindings.confirm() +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    // Use WidgetFrame for consistent frame rendering
    final paddedTitle = '  $label  ';
    final frame = WidgetFrame(
      title: paddedTitle,
      theme: theme,
      bindings: null, // We handle hints manually for calendar layout
    );

    void render(RenderOutput out) {
      frame.renderContent(out, (ctx) {
        // Month and year selector line
        final monthName = DateFormat('MMMM').format(viewMonth);
        final year = viewMonth.year.toString();
        final monthLine =
            '${theme.accent}‹${theme.reset}  ${theme.bold}$monthName $year${theme.reset}  ${theme.accent}›${theme.reset}';
        ctx.gutterLine(monthLine);

        // Weekdays
        final weekdays = startWeekOnMonday
            ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
            : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

        final weekdayLine =
            weekdays.map((d) => '${theme.dim}$d${theme.reset}').join(' ');
        ctx.gutterLine(weekdayLine);

        // Calendar math
        final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
        final daysInMonth =
            DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
        int firstWeekday = firstDay.weekday; // Monday = 1…Sunday = 7
        if (!startWeekOnMonday) {
          firstWeekday = (firstWeekday % 7) + 1; // Make Sunday start = 1
        }
        final startOffset = (firstWeekday - 1) % 7;
        int day = 1;
        final prevMonthDays = DateTime(viewMonth.year, viewMonth.month, 0).day;

        // Calendar body
        for (var week = 0; week < 6; week++) {
          final buffer = StringBuffer(ctx.lb.gutter());
          for (var wd = 0; wd < 7; wd++) {
            final cellIndex = week * 7 + wd;

            if (cellIndex < startOffset) {
              // Previous month trailing days
              final prevDay = prevMonthDays - (startOffset - wd) + 1;
              buffer.write(
                  '${theme.dim}${prevDay.toString().padLeft(2)}${theme.reset} ');
            } else if (day > daysInMonth) {
              // Next month leading days
              final nextDay = day - daysInMonth;
              buffer.write(
                  '${theme.dim}${nextDay.toString().padLeft(2)}${theme.reset} ');
              day++;
            } else {
              final current = DateTime(viewMonth.year, viewMonth.month, day);
              final isSelected = _sameDay(current, selected);
              final isToday = _sameDay(current, DateTime.now());
              final text = day.toString().padLeft(2);

              if (isSelected) {
                buffer.write('${theme.inverse}$text${theme.reset} ');
              } else if (isToday) {
                buffer.write('${theme.accent}$text${theme.reset} ');
              } else if (wd == 6) {
                buffer.write('${theme.dim}$text${theme.reset} ');
              } else {
                buffer.write('$text ');
              }
              day++;
            }
          }
          ctx.line(buffer.toString());
          if (day > daysInMonth && week > 3) break;
        }
      });

      // Footer hints generated from bindings
      out.writeln(Hints.bullets(
          bindings
              .toHintEntries()
              .map((e) => Hints.hint(e[0], e[1], theme))
              .toList(),
          theme));
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return (cancelled || result == PromptResult.cancelled) ? null : selected;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
