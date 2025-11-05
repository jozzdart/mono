import 'dart:math';

import '../lib/src/src.dart';

void main() {
  final rnd = Random();
  double t = 0.0;

  double nextValue() {
    t += 0.2;
    return 0.9 * sin(t) + 0.35 * sin(2.4 * t + 0.6) + 0.12 * (rnd.nextDouble() - 0.5);
  }

  LineChartWidget(
    'Line Chart · Realtime',
    theme: PromptTheme.pastel,
    width: 68,
    height: 14,
    tick: const Duration(milliseconds: 120),
    duration: const Duration(seconds: 10),
    yAutoScale: true,
    grid: ChartGrid.dots,
    generator: nextValue,
  ).run();
}


