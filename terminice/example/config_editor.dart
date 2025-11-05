import 'dart:io';

import 'package:terminice/src/src.dart';

void main() {
  final theme = PromptTheme.pastel;

  final initialJson = '''{
  "name": "terminice",
  "version": "1.0.0",
  "features": ["widgets", "prompts", "charts"],
  "debug": false
}''';

  final editor = ConfigEditor(
    title: 'Config Editor',
    theme: theme,
    language: 'auto', // try 'json' or 'yaml'
    initialText: initialJson,
    visibleLines: 12,
  );

  final result = editor.run();
  if (result.isEmpty) {
    stdout.writeln('${theme.dim}Cancelled.${theme.reset}');
  } else {
    stdout.writeln('\n${theme.info}Result:${theme.reset}\n$result');
  }
}


