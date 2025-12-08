import 'dart:io';

import 'package:terminice/terminice.dart';

void main() {
  final confirmed = ConfirmPrompt(
    label: 'Confirm',
    message: 'Do you want to continue with deployment?',
    theme: PromptTheme.matrix,
  ).run();

  stdout.writeln(confirmed
      ? '\n${PromptTheme.matrix.accent} Proceeding...'
      : '\n${PromptTheme.matrix.dim} Cancelled.');
}
