import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  Terminal.clearAndHome();

  final initial = '''
// Edit this Dart snippet. Press Ctrl+D to confirm, Esc to cancel.
import 'dart:math';

class Demo {
  final String name;
  Demo(this.name);
  void run() {
    final n = 42;
    print('Hello, ' + name + ' #' + n.toString());
  }
}
''';

  final editor = SnippetEditor(
    title: 'Snippet Editor',
    language: 'dart',
    theme: PromptTheme.dark,
    visibleLines: 12,
    initialText: initial,
  );

  final result = editor.run();

  stdout.writeln('\nResult:');
  Highlight(
    result,
    theme: PromptTheme.pastel,
    language: 'dart',
    title: 'Your Snippet',
    color: false,
    guides: true,
  ).show();
}


