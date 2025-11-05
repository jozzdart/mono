import 'dart:io';
import 'package:intl/intl.dart';
import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';

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
    final style = theme.style;
    final term = Terminal.enterRaw();

    DateTime selected = DateTime(initial.year, initial.month, initial.day);
    DateTime viewMonth = DateTime(selected.year, selected.month);
    bool cancelled = false;

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    void render() {
      Terminal.clearAndHome();

      // Frame header only contains the label
      final title = label;
      final paddedTitle = '  $title  ';
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.titleWithBorders(paddedTitle, theme));
      } else {
        stdout.writeln('${theme.accent}$paddedTitle${theme.reset}');
      }

      // Month and year selector line
      final monthName = DateFormat('MMMM').format(viewMonth);
      final year = viewMonth.year.toString();
      final monthLine =
          '${theme.accent}‹${theme.reset}  ${theme.bold}$monthName $year${theme.reset}  ${theme.accent}›${theme.reset}';
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} $monthLine');

      // Weekdays
      final weekdays = startWeekOnMonday
          ? ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
          : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

      final weekdayLine =
          weekdays.map((d) => '${theme.dim}$d${theme.reset}').join(' ');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} $weekdayLine');

      // Calendar math
      final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
      final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
      int firstWeekday = firstDay.weekday; // Monday = 1…Sunday = 7
      if (!startWeekOnMonday) {
        firstWeekday = (firstWeekday % 7) + 1; // Make Sunday start = 1
      }
      final startOffset = (firstWeekday - 1) % 7;
      int day = 1;
      final prevMonthDays = DateTime(viewMonth.year, viewMonth.month, 0).day;

      // Calendar body
      for (var week = 0; week < 6; week++) {
        final buffer =
            StringBuffer('${theme.gray}${style.borderVertical}${theme.reset} ');
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
        stdout.writeln(buffer.toString());
        if (day > daysInMonth && week > 3) break;
      }

      // Bottom border
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(paddedTitle, theme));
      }

      // Footer hints
      stdout.writeln(Hints.bullets([
        Hints.hint('←/→', 'day', theme),
        Hints.hint('↑/↓', 'week', theme),
        Hints.hint('W/S', 'year', theme),
        Hints.hint('Ctrl+E', 'today', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));
    }

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          break;
        }
        if (ev.type == KeyEventType.enter) break;

        // Ctrl+E → today
        if (ev.type == KeyEventType.cnrlE) {
          selected = DateTime.now();
          viewMonth = DateTime(selected.year, selected.month);
        }

        // ←/→ → move day
        if (ev.type == KeyEventType.arrowLeft) {
          selected = selected.subtract(const Duration(days: 1));
        } else if (ev.type == KeyEventType.arrowRight) {
          selected = selected.add(const Duration(days: 1));
        }

        // ↑/↓ → move week
        else if (ev.type == KeyEventType.arrowUp) {
          selected = selected.subtract(const Duration(days: 7));
        } else if (ev.type == KeyEventType.arrowDown) {
          selected = selected.add(const Duration(days: 7));
        }

        // W/S → move year
        else if (ev.type == KeyEventType.char &&
            ev.char?.toLowerCase() == 'w') {
          selected = DateTime(selected.year + 1, selected.month, selected.day);
        } else if (ev.type == KeyEventType.char &&
            ev.char?.toLowerCase() == 's') {
          selected = DateTime(selected.year - 1, selected.month, selected.day);
        }

        // Keep view month synced
        viewMonth = DateTime(selected.year, selected.month);
        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    return cancelled ? null : selected;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
