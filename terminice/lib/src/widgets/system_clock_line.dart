import 'dart:io';

import '../style/theme.dart';
import '../system/framed_layout.dart';

/// Describes an upcoming cron-style task/event.
class CronEvent {
  final String name;
  final DateTime scheduledAt;
  final String? source;

  CronEvent(this.name, this.scheduledAt, {this.source});
}

/// SystemClockLine – timeline of upcoming cron tasks.
///
/// Example:
///   final now = DateTime.now();
///   final widget = SystemClockLine([
///     CronEvent('Rotate logs', now.add(Duration(minutes: 5))),
///     CronEvent('Backup DB', now.add(Duration(minutes: 18))),
///   ], theme: PromptTheme.pastel);
///   widget.run();
class SystemClockLine {
  final List<CronEvent> events;
  final PromptTheme theme;
  final String? title;
  final Duration window;
  final int maxItems;
  final int trackWidth;
  final DateTime Function() _clock;

  SystemClockLine(
    this.events, {
    this.theme = const PromptTheme(),
    this.title,
    this.window = const Duration(hours: 2),
    this.maxItems = 12,
    this.trackWidth = 28,
    DateTime Function()? now,
  }) : _clock = now ?? DateTime.now;

  void run() {
    final label = title ?? 'System Clock Line';
    final style = theme.style;
    final now = _clock();

    // Prepare list: future-only, within window, sorted.
    final until = now.add(window);
    final upcoming = events
        .where((e) => !e.scheduledAt.isBefore(now) && !e.scheduledAt.isAfter(until))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Header
    final frame = FramedLayout(label, theme: theme);
    stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');

    // Legend + connector
    final nowStr = _fmtTime(now);
    stdout.writeln('${theme.gray}${style.borderVertical}${theme.reset} '
        '${theme.gray}Window:${theme.reset} ${theme.selection}${_fmtWindow(window)}${theme.reset}  '
        '${theme.gray}Events:${theme.reset} ${theme.accent}${upcoming.length}${theme.reset}  '
        '${theme.gray}Now:${theme.reset} ${theme.accent}$nowStr${theme.reset}');
    stdout.writeln(frame.connector());

    if (upcoming.isEmpty) {
      stdout.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} '
        '${theme.dim}No upcoming tasks in next ${_fmtWindow(window)}${theme.reset}',
      );
      if (style.showBorder) {
        stdout.writeln(frame.bottom());
      }
      return;
    }

    // Column widths
    final nameWidth = _cap(_maxLen(upcoming.map((e) => e.name.length)), 12, 36);
    final srcWidth = _cap(_maxLen(upcoming.map((e) => (e.source ?? '').length)), 0, 18);

    int printed = 0;
    for (final e in upcoming) {
      if (printed >= maxItems) break;
      printed++;

      final at = _fmtTime(e.scheduledAt);
      final delta = e.scheduledAt.difference(now);
      final til = _fmtDelta(delta);
      final icon = _timeIcon(delta);
      final name = _pad(e.name, nameWidth);
      final src = (e.source != null && e.source!.isNotEmpty)
          ? ' ${theme.gray}[${_pad(e.source!, srcWidth)}]${theme.reset}'
          : '';

      // Primary info line
      stdout.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} '
        '$icon ${theme.accent}$at${theme.reset}  '
        '${theme.bold}${theme.selection}$name${theme.reset}  '
        '${theme.gray}$til${theme.reset}$src',
      );

      // Proportional timeline line
      final pos = _positionInWindow(now, e.scheduledAt).clamp(0.0, 1.0);
      final idx = (pos * trackWidth).round().clamp(0, trackWidth);
      final track = StringBuffer();
      for (var i = 0; i <= trackWidth; i++) {
        if (i == idx) {
          track.write('${theme.accent}${theme.bold}${theme.style.checkboxOnSymbol}${theme.reset}');
        } else {
          track.write('${theme.gray}─${theme.reset}');
        }
      }
      stdout.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} '
        '${theme.dim}${_pad('', at.length)}${theme.reset}  ' // align under time
        '$track',
      );
    }

    if (style.showBorder) {
      stdout.writeln(frame.bottom());
    }
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDelta(Duration d) {
    if (d.inSeconds <= 0) return 'now';
    if (d.inMinutes < 1) return 'in ${d.inSeconds}s';
    if (d.inHours < 1) return 'in ${d.inMinutes}m';
    final hrs = d.inHours;
    final mins = d.inMinutes % 60;
    return mins == 0 ? 'in ${hrs}h' : 'in ${hrs}h ${mins}m';
  }

  String _fmtWindow(Duration d) {
    if (d.inHours >= 1 && d.inMinutes % 60 == 0) return '${d.inHours}h';
    if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  int _maxLen(Iterable<int> lengths) {
    var max = 0;
    for (final l in lengths) {
      if (l > max) max = l;
    }
    return max;
  }

  int _cap(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  String _pad(String text, int width) {
    if (text.length >= width) return text;
    return text + ' ' * (width - text.length);
  }

  String _timeIcon(Duration until) {
    if (until.inMinutes <= 1) return '${theme.highlight}!${theme.reset}';
    if (until.inMinutes <= 10) return '${theme.info}${theme.style.arrow}${theme.reset}';
    return '${theme.gray}·${theme.reset}';
  }

  double _positionInWindow(DateTime now, DateTime when) {
    final total = window.inMilliseconds;
    final passed = when.difference(now).inMilliseconds;
    return passed / (total == 0 ? 1 : total);
  }
}


