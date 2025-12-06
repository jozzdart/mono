import 'dart:io';

import 'package:terminice/terminice.dart';

Future<void> main() async {
  stdout.writeln('Fetching weather...');

  final widget = WeatherWidget.city(
    'San Francisco',
    theme: PromptTheme.matrix,
    unit: TemperatureUnit.celsius,
  );

  await widget.show();
}
