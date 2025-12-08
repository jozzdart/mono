import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  _runWithTheme(PromptTheme.pastel);
  _runWithTheme(PromptTheme.matrix);
  _runWithTheme(PromptTheme.fire);
  _runWithTheme(PromptTheme.arcane);
  _runWithTheme(PromptTheme.phantom);
}

void _runWithTheme(PromptTheme theme) {
  final password = PasswordPrompt(
    prompt: 'Enter your password',
    theme: theme,
  ).run();

  if (password == null || password.isEmpty) {
    stdout.writeln(
        '${PromptTheme.pastel.dim}Cancelled.${PromptTheme.pastel.reset}');
  } else {
    stdout.writeln(
        '\n${PromptTheme.pastel.accent}Password entered (${password.length} chars)${PromptTheme.pastel.reset}');
  }
}
