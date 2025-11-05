import 'dart:io';

import 'package:terminice/src/widgets/slider_prompt.dart';
import 'package:terminice/src/style/theme.dart';

void main() {
  final brightness = SliderPrompt(
    'Screen Brightness',
    min: 0,
    max: 100,
    initial: 40,
    step: 5,
    theme: PromptTheme.matrix,
  ).run();

  stdout.writeln(
      '\n${PromptTheme.matrix.accent}Brightness set to ${brightness.toStringAsFixed(0)}%${PromptTheme.matrix.reset}');

  final volume = SliderPrompt(
    'Volume',
    min: 0,
    max: 100,
    initial: 40,
    step: 5,
    theme: PromptTheme.fire,
  ).run();

  stdout.writeln(
      '\n${PromptTheme.fire.accent}Volume set to ${volume.toStringAsFixed(0)}%${PromptTheme.fire.reset}');
}
