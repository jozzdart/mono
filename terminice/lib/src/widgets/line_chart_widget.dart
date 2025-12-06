import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/widget_frame.dart';

/// LineChartWidget – ASCII-based real-time line plot.
///
/// Aligns with ThemeDemo styling: titled frame, themed left gutter,
/// tasteful use of accent/highlight colors, and concise hints.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// LineChartWidget('CPU').withMatrixTheme().run();
/// ```
class LineChartWidget with Themeable {
  final String title;
  @override
  final PromptTheme theme;
  final int width;
  final int height;
  final Duration tick;
  final Duration? duration;
  final bool yAutoScale;
  final double? yMin;
  final double? yMax;
  final ChartGrid grid;
  final double gridStep; // logical step between grid lines (y-units)
  final double paddingFrac; // extra headroom for autoscale

  /// Optional data source: if provided, polled each tick.
  /// If null, an internal demo generator is used.
  final double Function()? generator;

  LineChartWidget(
    this.title, {
    this.theme = PromptTheme.dark,
    this.width = 64,
    this.height = 12,
    this.tick = const Duration(milliseconds: 120),
    this.duration,
    this.yAutoScale = true,
    this.yMin,
    this.yMax,
    this.grid = ChartGrid.dots,
    this.gridStep = 0.5,
    this.paddingFrac = 0.08,
    this.generator,
  })  : assert(width >= 16),
        assert(height >= 6),
        assert(!tick.isNegative && tick > Duration.zero),
        assert(yAutoScale || (yMin != null && yMax != null && yMax > yMin));

  @override
  LineChartWidget copyWithTheme(PromptTheme theme) {
    return LineChartWidget(
      title,
      theme: theme,
      width: width,
      height: height,
      tick: tick,
      duration: duration,
      yAutoScale: yAutoScale,
      yMin: yMin,
      yMax: yMax,
      grid: grid,
      gridStep: gridStep,
      paddingFrac: paddingFrac,
      generator: generator,
    );
  }

  Future<void> run() async {
    PromptTheme currentTheme = theme;
    bool autoScale = yAutoScale;
    bool showZero = true;
    ChartGrid gridMode = grid;
    int chartWidth = width;
    int chartHeight = height;

    // Circular buffer of recent points
    final data = List<double?>.filled(chartWidth, null);
    int head = 0;
    double t = 0.0;
    final rnd = Random();

    double demoGen() {
      t += 0.18;
      // Pleasant composite wave with light noise
      return 0.8 * sin(t) +
          0.35 * sin(2.6 * t + 0.7) +
          0.15 * (rnd.nextDouble() - 0.5);
    }

    void push(double v) {
      data[head % chartWidth] = v;
      head = (head + 1) % chartWidth;
    }

    List<double> window() {
      final out = <double>[];
      for (int i = 0; i < chartWidth; i++) {
        final idx = (head + i) % chartWidth; // oldest..newest
        final v = data[idx];
        if (v != null) out.add(v);
      }
      return out;
    }

    (double lo, double hi) range() {
      if (!autoScale) {
        final lo = yMin;
        final hi = yMax;
        if (lo != null && hi != null && hi > lo) {
          return (lo, hi);
        }
        // Fallback to computed window range if provided limits are missing/invalid
        final w = window();
        if (w.isEmpty) return (-1.0, 1.0);
        double vlo = w.first;
        double vhi = w.first;
        for (final v in w) {
          if (v < vlo) vlo = v;
          if (v > vhi) vhi = v;
        }
        if (vlo == vhi) {
          vlo -= 1.0;
          vhi += 1.0;
        }
        final pad = max(0.001, (vhi - vlo) * paddingFrac);
        return (vlo - pad, vhi + pad);
      }
      final w = window();
      if (w.isEmpty) return (-1.0, 1.0);
      double lo = w.first;
      double hi = w.first;
      for (final v in w) {
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
      if (lo == hi) {
        lo -= 1.0;
        hi += 1.0;
      }
      final pad = max(0.001, (hi - lo) * paddingFrac);
      return (lo - pad, hi + pad);
    }

    int yToRow(double y, double lo, double hi) {
      final span = hi - lo;
      final ratio = (y - lo) / span;
      final r = (chartHeight - 1) - (ratio * (chartHeight - 1));
      return r.round().clamp(0, chartHeight - 1);
    }

    final session = TerminalSession(hideCursor: true, rawMode: true);
    session.start();
    final out = RenderOutput();

    void render() {
      out.clear();

      // Determine range and zero line
      final (lo, hi) = range();
      final zeroRow =
          (showZero && lo <= 0 && 0 <= hi) ? yToRow(0.0, lo, hi) : null;

      // Prebuild empty canvas
      final gridChars = List.generate(
        chartHeight,
        (_) => List.filled(chartWidth, ' '),
      );

      // Gridlines
      if (gridMode != ChartGrid.none) {
        // Horizontal gridlines at multiples of gridStep within [lo, hi]
        if (gridStep > 0) {
          final start = (lo / gridStep).ceil();
          final end = (hi / gridStep).floor();
          for (int k = start; k <= end; k++) {
            final yVal = k * gridStep;
            final r = yToRow(yVal, lo, hi);
            for (int c = 0; c < chartWidth; c++) {
              if (gridMode == ChartGrid.lines) {
                gridChars[r][c] = '-';
              } else if (gridMode == ChartGrid.dots && (c % 2 == 0)) {
                gridChars[r][c] = '·';
              }
            }
          }
        }
      }

      // Zero line (overrides grid char at that row)
      if (zeroRow != null) {
        for (int c = 0; c < chartWidth; c++) {
          gridChars[zeroRow][c] = '─';
        }
      }

      // Plot data as connected line
      final points = <(int x, int r)>[];
      for (int i = 0; i < chartWidth; i++) {
        final idx = (head + i) % chartWidth; // oldest..newest ← left..right
        final v = data[idx];
        if (v == null) continue;
        final rr = yToRow(v, lo, hi);
        points.add((i, rr));
      }

      void plotPoint(int x, int r) {
        if (x >= 0 && x < chartWidth && r >= 0 && r < chartHeight) {
          gridChars[r][x] = '•';
        }
      }

      // Draw lines between consecutive points using simple vertical fill
      for (int i = 1; i < points.length; i++) {
        final (x0, r0) = points[i - 1];
        final (x1, r1) = points[i];
        if (x1 == x0) {
          plotPoint(x0, r0);
          continue;
        }
        // Connect all intervening x's if any are skipped (in case of nulls)
        final dx = x1 - x0;
        for (int x = x0; x <= x1; x++) {
          final tLerp = dx == 0 ? 0.0 : (x - x0) / dx;
          final r = (r0 + (r1 - r0) * tLerp).round();
          plotPoint(x, r);
        }
      }

      // Use WidgetFrame for consistent frame rendering
      final wf = WidgetFrame(
        title: title,
        theme: currentTheme,
        hintStyle: HintStyle.none, // Manual hints below
      );

      wf.showTo(out, (ctx) {
        // Compose lines
        for (int r = 0; r < chartHeight; r++) {
          final row = StringBuffer();
          for (int c = 0; c < chartWidth; c++) {
            final ch = gridChars[r][c];
            if (ch == '•') {
              row.write(
                  '${currentTheme.accent}${currentTheme.bold}•${currentTheme.reset}');
            } else if (ch == '─') {
              row.write('${currentTheme.dim}─${currentTheme.reset}');
            } else if (ch == '-' || ch == '·') {
              row.write('${currentTheme.gray}$ch${currentTheme.reset}');
            } else {
              row.write(' ');
            }
          }
          ctx.gutterLine(row.toString());
        }

        // Summary line
        final stats = window();
        final latest = stats.isNotEmpty ? stats.last : null;
        final loStr = stats.isNotEmpty ? _fmt(stats.reduce(min)) : '—';
        final hiStr = stats.isNotEmpty ? _fmt(stats.reduce(max)) : '—';
        final lastStr = latest != null ? _fmt(latest) : '—';
        final rangeStr =
            '${currentTheme.dim}y:[${currentTheme.reset}${currentTheme.gray}${_fmt(lo)}${currentTheme.reset}${currentTheme.dim}, ${currentTheme.gray}${_fmt(hi)}${currentTheme.reset}${currentTheme.dim}]${currentTheme.reset}';
        final info =
            '${currentTheme.gray}min ${currentTheme.reset}${currentTheme.warn}$loStr${currentTheme.reset}  '
            '${currentTheme.gray}max ${currentTheme.reset}${currentTheme.info}$hiStr${currentTheme.reset}  '
            '${currentTheme.gray}last ${currentTheme.reset}${currentTheme.highlight}$lastStr${currentTheme.reset}  $rangeStr';

        ctx.gutterLine(info);
      });

      // Hints
      out.writeln(Hints.grid([
        [Hints.key('A', currentTheme), 'toggle autoscale'],
        [Hints.key('G', currentTheme), 'toggle grid'],
        [Hints.key('Z', currentTheme), 'toggle zero-line'],
        [Hints.key('W/S', currentTheme), 'height ±1'],
        [Hints.key('←/→', currentTheme), 'width ±2'],
        [Hints.key('T', currentTheme), 'cycle theme'],
        [Hints.key('Ctrl+C / Esc', currentTheme), 'exit'],
      ], currentTheme));
    }

    PromptTheme nextTheme(PromptTheme t) {
      if (identical(t, PromptTheme.dark)) return PromptTheme.matrix;
      if (identical(t, PromptTheme.matrix)) return PromptTheme.fire;
      if (identical(t, PromptTheme.fire)) return PromptTheme.pastel;
      return PromptTheme.dark;
    }

    // Input handling
    StreamSubscription<List<int>>? sub;
    Timer? timer;
    bool running = true;
    final done = Completer<void>();

    void onKey(int b) {
      // Ctrl+C or ESC
      if (b == 3 || b == 27) {
        running = false;
        if (!done.isCompleted) done.complete();
        return;
      }
      // Enter
      if (b == 10 || b == 13) {
        running = false;
        if (!done.isCompleted) done.complete();
        return;
      }

      // Arrow keys (ESC [ A/B/C/D)
      if (b == 27) {
        final n1 = Terminal.tryReadNextByte();
        final n2 = Terminal.tryReadNextByte();
        if (n1 == 91 /*[*/ && n2 != null) {
          if (n2 == 65) {
            // Up
            chartHeight = (chartHeight + 1).clamp(6, 24);
          } else if (n2 == 66) {
            // Down
            chartHeight = (chartHeight - 1).clamp(6, 24);
          } else if (n2 == 67) {
            // Right
            chartWidth = (chartWidth + 2).clamp(24, 128);
            // Rebuild buffer preserving newest points
            final cur = window();
            final newBuf = List<double?>.filled(chartWidth, null);
            int start = max(0, cur.length - chartWidth);
            int j = 0;
            for (int i = start; i < cur.length; i++) {
              newBuf[j++] = cur[i];
            }
            for (int i = 0; i < chartWidth; i++) {
              data[i % chartWidth] = newBuf[i];
            }
            head = j % chartWidth;
          } else if (n2 == 68) {
            // Left
            chartWidth = (chartWidth - 2).clamp(24, 128);
            final cur = window();
            final newBuf = List<double?>.filled(chartWidth, null);
            int start = max(0, cur.length - chartWidth);
            int j = 0;
            for (int i = start; i < cur.length; i++) {
              newBuf[j++] = cur[i];
            }
            for (int i = 0; i < chartWidth; i++) {
              data[i % chartWidth] = newBuf[i];
            }
            head = j % chartWidth;
          }
        }
        return;
      }

      final ch = String.fromCharCode(b).toLowerCase();
      if (ch == 'a') autoScale = !autoScale;
      if (ch == 'g') {
        gridMode = gridMode == ChartGrid.none
            ? ChartGrid.dots
            : (gridMode == ChartGrid.dots ? ChartGrid.lines : ChartGrid.none);
      }
      if (ch == 'z') showZero = !showZero;
      if (ch == 't') currentTheme = nextTheme(currentTheme);
      if (ch == 'w') chartHeight = (chartHeight + 1).clamp(6, 24);
      if (ch == 's') chartHeight = (chartHeight - 1).clamp(6, 24);
    }

    try {
      // Seed a few points for nicer initial picture
      for (int i = 0; i < min(12, chartWidth); i++) {
        push((generator ?? demoGen)());
      }

      final watch = Stopwatch()..start();
      timer = Timer.periodic(tick, (_) {
        if (!running) return;
        push((generator ?? demoGen)());
        render();
        if (duration != null && watch.elapsed >= duration!) {
          running = false;
          if (!done.isCompleted) done.complete();
        }
      });

      // Input subscription
      sub = stdin.listen((dataBytes) {
        for (final b in dataBytes) {
          onKey(b);
        }
        if (running) render();
        if (!running && !done.isCompleted) done.complete();
      });

      // First paint
      render();
      await done.future;
    } finally {
      timer?.cancel();
      await _awaitVoid(sub?.cancel());
      session.end();
      out.clear();
    }
  }

  String _fmt(double v) {
    String s = v.toStringAsFixed(2);
    if (s == '-0.00') s = '0.00';
    return s;
  }
}

enum ChartGrid { none, dots, lines }

Future<void> _awaitVoid(Future<void>? f) async {
  if (f != null) {
    try {
      await f;
    } catch (_) {}
  }
}
