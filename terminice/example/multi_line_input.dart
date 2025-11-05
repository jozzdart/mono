import 'dart:io';

import 'package:terminice/src/widgets/multi_line_input.dart';
import 'package:terminice/src/style/theme.dart';

void main() {
  final input = MultiLineInputPrompt(
    label: 'Write your description',
    theme: PromptTheme.pastel,
  ).run();

  if (input.isEmpty) {
    stdout.writeln(
        '${PromptTheme.pastel.dim}Cancelled.${PromptTheme.pastel.reset}');
  } else {
    stdout.writeln(
        '\n${PromptTheme.pastel.accent}You wrote:${PromptTheme.pastel.reset}\n$input');
  }
}
