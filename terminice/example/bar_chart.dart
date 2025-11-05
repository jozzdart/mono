import 'package:terminice/terminice.dart';

void main() {
  Terminal.clearAndHome();

  final items = <BarChartItem>[
    const BarChartItem('Alpha', 42),
    const BarChartItem('Beta', 67),
    const BarChartItem('Gamma', 25),
    const BarChartItem('Delta', 84),
    const BarChartItem('Epsilon', 57),
  ];

  final chart = BarChartWidget(
    items,
    theme: PromptTheme.pastel, // Try .dark, .matrix, .fire, .pastel
    title: 'Bar Chart · Demo',
    barWidth: 32,
    showValues: true,
    style: BarStyle.thin,
    valueFormatter: (v) => v.toStringAsFixed(0),
  );

  chart.show();
}
