import 'dart:io';

import 'package:terminice/src/widgets/password.dart';
import 'package:terminice/src/style/theme.dart';

void main() async {
  await _runWithTheme(PromptTheme.pastel);
  await _runWithTheme(PromptTheme.matrix);
  await _runWithTheme(PromptTheme.fire);
  await _runWithTheme(PromptTheme.arcane);
  await _runWithTheme(PromptTheme.phantom);
}

Future<void> _runWithTheme(PromptTheme theme) async {
  final password = await PasswordPrompt(
    label: 'Enter your password',
    theme: theme,
  ).run();

  if (password.isEmpty) {
    stdout.writeln(
        '${PromptTheme.pastel.dim}Cancelled.${PromptTheme.pastel.reset}');
  } else {
    stdout.writeln(
        '\n${PromptTheme.pastel.accent}Password entered (${password.length} chars)${PromptTheme.pastel.reset}');
  }
}
