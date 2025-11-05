import 'dart:io';

import 'package:terminice/src/widgets/confirm_prompt.dart';
import 'package:terminice/src/style/theme.dart';

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
