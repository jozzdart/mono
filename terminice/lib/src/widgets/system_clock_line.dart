import '../style/theme.dart';
import '../system/text_utils.dart' as text;
import '../system/widget_frame.dart';

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
    final now = _clock();

    // Prepare list: future-only, within window, sorted.
    final until = now.add(window);
    final upcoming = events
        .where((e) => !e.scheduledAt.isBefore(now) && !e.scheduledAt.isAfter(until))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final frame = WidgetFrame(title: label, theme: theme, showConnector: true);
    frame.show((ctx) {
      // Legend
      final nowStr = _fmtTime(now);
      ctx.gutterLine(
          '${theme.gray}Window:${theme.reset} ${theme.selection}${_fmtWindow(window)}${theme.reset}  '
          '${theme.gray}Events:${theme.reset} ${theme.accent}${upcoming.length}${theme.reset}  '
          '${theme.gray}Now:${theme.reset} ${theme.accent}$nowStr${theme.reset}');
      ctx.writeConnector();

      if (upcoming.isEmpty) {
        ctx.emptyMessage('No upcoming tasks in next ${_fmtWindow(window)}');
        return;
      }

      // Column widths
      final nameWidth = text.clampInt(text.maxOf(upcoming.map((e) => e.name.length)), 12, 36);
      final srcWidth = text.clampInt(text.maxOf(upcoming.map((e) => (e.source ?? '').length)), 0, 18);

      int printed = 0;
      for (final e in upcoming) {
        if (printed >= maxItems) break;
        printed++;

        final at = _fmtTime(e.scheduledAt);
        final delta = e.scheduledAt.difference(now);
        final til = _fmtDelta(delta);
        final icon = _timeIcon(delta);
        final name = text.padRight(e.name, nameWidth);
        final src = (e.source != null && e.source!.isNotEmpty)
            ? ' ${theme.gray}[${text.padRight(e.source!, srcWidth)}]${theme.reset}'
            : '';

        // Primary info line
        ctx.gutterLine(
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
        ctx.gutterLine(
          '${theme.dim}${text.padRight('', at.length)}${theme.reset}  $track',
        );
      }
    });
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


