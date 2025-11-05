import '../lib/src/src.dart';

void main() {
  UnitConverter(
    theme: PromptTheme.pastel,
    title: 'Unit Converter · Demo',
    centimeters: 10,
    usd: 100,
    usdToEurRate: 0.92,
  ).run();
}


