import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  final nav = DocNavigator(
    title: 'Docs · Demo',
    theme: PromptTheme.pastel, // Try .dark, .matrix, .fire, .pastel
    root: Directory.current,
    showHidden: false,
    maxVisible: 18,
  );

  final selected = nav.run();

  if (selected != null && selected.isNotEmpty) {
    stdout.writeln('Selected: $selected');
  } else {
    stdout.writeln('No selection');
  }
}
