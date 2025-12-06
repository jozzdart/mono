import 'dart:io';
import 'dart:math';
import 'dart:async';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';

/// ClockWidget – analog/digital terminal clock.
///
/// Aligns with ThemeDemo styling: titled frame, themed left gutter,
/// tasteful use of accent/highlight colors, and concise hints.
class ClockWidget {
  final String title;
  final PromptTheme theme;
  final bool analog;
  final bool digital;
  final bool showSeconds;
  final int radius;
  final Duration tick;
  final Duration? duration;
  final ClockLayout layout;

  ClockWidget(
    this.title, {
    this.theme = PromptTheme.dark,
    this.analog = true,
    this.digital = true,
    this.showSeconds = true,
    this.radius = 7,
    this.tick = const Duration(seconds: 1),
    this.duration,
    this.layout = ClockLayout.stacked,
  }) : assert(radius >= 4, 'radius should be >= 4 for a readable clock');

  Future<void> run() async {
    PromptTheme currentTheme = theme;
    bool showAnalog = analog;
    bool showDigital = digital;
    bool withSeconds = showSeconds;
    int r = radius;
    ClockLayout mode = layout;

    final session = TerminalSession(hideCursor: true, rawMode: true);
    session.start();
    final out = RenderOutput();

    String modeLabel() {
      final s = showAnalog && showDigital
          ? 'Analog + Digital'
          : showAnalog
              ? 'Analog'
              : 'Digital';
      final l = mode == ClockLayout.sideBySide ? 'Side-by-side' : 'Stacked';
      return '$s · $l';
    }

    String topTitle() {
      final frame =
          FramedLayout('$title · ${modeLabel()}', theme: currentTheme);
      return frame.top();
    }

    String formatTime(DateTime t) {
      two(int n) => n.toString().padLeft(2, '0');
      final hh = two(t.hour);
      final mm = two(t.minute);
      final ss = two(t.second);
      if (!withSeconds) return '$hh:$mm';
      return '$hh:$mm:$ss';
    }

    List<String> renderAnalog(DateTime now) {
      final d = r * 2 + 1;
      final cx = r;
      final cy = r;

      final grid = List.generate(d, (_) => List.generate(d, (_) => ' '));

      bool onCircle(int x, int y) {
        final dx = x - cx;
        final dy = y - cy;
        final dist2 = dx * dx + dy * dy;
        final rr = r - 0.5;
        return (dist2 >= (rr * rr) && dist2 <= ((r + 0.2) * (r + 0.2)));
      }

      void plot(int x, int y, String ch) {
        if (x >= 0 && x < d && y >= 0 && y < d) {
          grid[y][x] = ch;
        }
      }

      // Circle outline
      for (var y = 0; y < d; y++) {
        for (var x = 0; x < d; x++) {
          if (onCircle(x, y)) {
            plot(x, y, '${currentTheme.gray}·${currentTheme.reset}');
          }
        }
      }

      // Hour tick marks (strong at 12/3/6/9)
      for (var h = 0; h < 12; h++) {
        final a = (pi / 6) * h - pi / 2;
        final isCardinal = h % 3 == 0;
        final rr = isCardinal ? r - 1 : r - 2;
        final tx = cx + (rr * cos(a)).round();
        final ty = cy + (rr * sin(a)).round();
        final ch = isCardinal
            ? '${currentTheme.accent}•${currentTheme.reset}'
            : '${currentTheme.dim}•${currentTheme.reset}';
        plot(tx, ty, ch);
        if (isCardinal) {
          final ix = cx + ((rr - 1) * cos(a)).round();
          final iy = cy + ((rr - 1) * sin(a)).round();
          plot(ix, iy, '${currentTheme.dim}·${currentTheme.reset}');
        }
      }

      // Hand angles
      final second = now.second + now.millisecond / 1000.0;
      final minute = now.minute + second / 60.0;
      final hour = (now.hour % 12) + minute / 60.0;

      double angleFromUnits(double units, double perRound) {
        return (2 * pi * (units / perRound)) - pi / 2;
      }

      final aHour = angleFromUnits(hour, 12);
      final aMin = angleFromUnits(minute, 60);
      final aSec = angleFromUnits(second, 60);

      void line0(double ax, double ay, double bx, double by, String ch) {
        int x0 = ax.round();
        int y0 = ay.round();
        final x1 = bx.round();
        final y1 = by.round();
        final dx = (x1 - x0).abs();
        final sx = x0 < x1 ? 1 : -1;
        final dy = -(y1 - y0).abs();
        final sy = y0 < y1 ? 1 : -1;
        var err = dx + dy;
        while (true) {
          plot(x0, y0, ch);
          if (x0 == x1 && y0 == y1) break;
          final e2 = 2 * err;
          if (e2 >= dy) {
            err += dy;
            x0 += sx;
          }
          if (e2 <= dx) {
            err += dx;
            y0 += sy;
          }
        }
      }

      // Hand endpoints
      final hx = cx + ((r - 3) * cos(aHour));
      final hy = cy + ((r - 3) * sin(aHour));
      final mx = cx + ((r - 2) * cos(aMin));
      final my = cy + ((r - 2) * sin(aMin));
      final sx = cx + ((r - 1) * cos(aSec));
      final sy = cy + ((r - 1) * sin(aSec));

      // Draw hands (order: hour, minute, second)
      line0(cx.toDouble(), cy.toDouble(), hx, hy,
          '${currentTheme.accent}${currentTheme.bold}·${currentTheme.reset}');
      line0(cx.toDouble(), cy.toDouble(), mx, my,
          '${currentTheme.highlight}${currentTheme.bold}·${currentTheme.reset}');
      if (withSeconds) {
        line0(cx.toDouble(), cy.toDouble(), sx, sy,
            '${currentTheme.selection}·${currentTheme.reset}');
      }

      // Center cap
      plot(cx, cy,
          '${currentTheme.bold}${currentTheme.accent}•${currentTheme.reset}');

      return grid.map((row) => row.join()).toList();
    }

    List<String> renderDigital(DateTime now) {
      final date = now.toIso8601String().substring(0, 10);
      final t = formatTime(now);
      final parts = t.split(':');
      final hh = parts[0];
      final mm = parts.length > 1 ? parts[1] : '';
      final ss = parts.length > 2 ? parts[2] : '';

      final line = StringBuffer();
      line
        ..write(
            '${currentTheme.bold}${currentTheme.accent}$hh${currentTheme.reset}')
        ..write('${currentTheme.dim}:${currentTheme.reset}')
        ..write(
            '${currentTheme.bold}${currentTheme.highlight}$mm${currentTheme.reset}');
      if (withSeconds) {
        line
          ..write('${currentTheme.dim}:${currentTheme.reset}')
          ..write('${currentTheme.selection}$ss${currentTheme.reset}');
      }
      final dateLine = '${currentTheme.gray}$date${currentTheme.reset}';
      return [line.toString(), dateLine];
    }

    void render() {
      final style = currentTheme.style;
      out.clear();
      final top = topTitle();
      out.writeln('${currentTheme.bold}$top${currentTheme.reset}');

      if (style.showBorder) {
        final frame = FramedLayout(title, theme: currentTheme);
        out.writeln(frame.connector());
      }

      // Use centralized line builder for consistent styling
      final lb = LineBuilder(currentTheme);
      final left = lb.gutter();
      final now = DateTime.now();

      if (showAnalog && showDigital && mode == ClockLayout.sideBySide) {
        final analogLines = renderAnalog(now);
        final digitalLines = renderDigital(now);
        final analogWidth = analogLines.isEmpty ? 0 : analogLines.first.length;
        final gap = 4;
        final height = analogLines.length;
        for (var i = 0; i < height; i++) {
          final a = analogLines[i];
          final dLine = i < digitalLines.length ? digitalLines[i] : '';
          final pad = ' ' * (analogWidth - a.length);
          out.writeln('$left$a$pad${' ' * gap}$dLine');
        }
      } else {
        if (showAnalog) {
          final lines = renderAnalog(now);
          for (final l in lines) {
            out.writeln('$left$l');
          }
        }
        if (showDigital) {
          if (showAnalog) out.writeln(left);
          final lines = renderDigital(now);
          for (final l in lines) {
            out.writeln('$left$l');
          }
        }
      }

      if (style.showBorder) {
        final frame = FramedLayout(title, theme: currentTheme);
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.grid([
        [Hints.key('A', currentTheme), 'toggle analog'],
        [Hints.key('D', currentTheme), 'toggle digital'],
        [Hints.key('B', currentTheme), 'both'],
        [Hints.key('S', currentTheme), 'toggle seconds'],
        [Hints.key('T', currentTheme), 'cycle theme'],
        [Hints.key('L', currentTheme), 'layout'],
        [Hints.key('+/-', currentTheme), 'radius'],
        [Hints.key('Ctrl+C / Esc', currentTheme), 'exit'],
      ], currentTheme));
    }

    Timer? timer;
    StreamSubscription<List<int>>? sub;
    bool running = true;
    final done = Completer<void>();

    PromptTheme nextTheme(PromptTheme t) {
      if (identical(t, PromptTheme.dark)) return PromptTheme.matrix;
      if (identical(t, PromptTheme.matrix)) return PromptTheme.fire;
      if (identical(t, PromptTheme.fire)) return PromptTheme.pastel;
      return PromptTheme.dark;
    }

    void onKey(int byte) {
      // Ctrl+C or ESC
      if (byte == 3 || byte == 27) {
        running = false;
        if (!done.isCompleted) done.complete();
        return;
      }
      // Enter
      if (byte == 10 || byte == 13) {
        running = false;
        if (!done.isCompleted) done.complete();
        return;
      }
      // Printable
      final ch = String.fromCharCode(byte).toLowerCase();
      if (ch == 'a') showAnalog = !showAnalog;
      if (ch == 'd') showDigital = !showDigital;
      if (ch == 'b') {
        showAnalog = true;
        showDigital = true;
      }
      if (ch == 's') withSeconds = !withSeconds;
      if (ch == 't') currentTheme = nextTheme(currentTheme);
      if (ch == 'l') {
        mode = mode == ClockLayout.stacked
            ? ClockLayout.sideBySide
            : ClockLayout.stacked;
      }
      if (byte == 43 /*+*/) r = (r + 1).clamp(4, 12);
      if (byte == 45 /*-*/) r = (r - 1).clamp(4, 12);
    }

    try {
      final watch = Stopwatch()..start();
      timer = Timer.periodic(tick, (_) {
        if (!running) return;
        render();
        if (duration != null && watch.elapsed >= duration!) {
          running = false;
          if (!done.isCompleted) done.complete();
        }
      });

      sub = stdin.listen((data) {
        for (final b in data) {
          onKey(b);
        }
        if (running) render();
        if (!running && !done.isCompleted) done.complete();
      });

      // Initial paint
      render();
      await done.future;
    } finally {
      timer?.cancel();
      awaitFuture(sub?.cancel());
      session.end();
      out.clear();
    }
  }
}

enum ClockLayout { stacked, sideBySide }

Future<void> awaitFuture(Future<void>? f) async {
  if (f != null) {
    try {
      await f;
    } catch (_) {}
  }
}
