import 'dart:io';

import 'package:terminice/src/widgets/password.dart';
import 'package:terminice/src/style/theme.dart';

void main() async {
  final password = await PasswordPrompt(
    label: 'Enter your password',
    theme: PromptTheme.pastel,
  ).run();

  if (password.isEmpty) {
    stdout.writeln(
        '${PromptTheme.pastel.dim}Cancelled.${PromptTheme.pastel.reset}');
  } else {
    stdout.writeln(
        '\n${PromptTheme.pastel.accent}Password entered (${password.length} chars)${PromptTheme.pastel.reset}');
  }
}
