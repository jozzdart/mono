import '../lib/src/src.dart';
import 'dart:io';

void main() {
  final steps = [
    'Project name',
    'Select template',
    'Configure options',
    'Initialize Git',
    'Review & finish',
  ];

  final wizard = StepperPrompt(
    title: 'Setup Wizard',
    steps: steps,
    theme: PromptTheme.pastel, // aligns with ThemeDemo aesthetics
    startIndex: 0,
  );

  final result = wizard.run();
  if (result < 0) {
    stdout.writeln('Wizard cancelled.');
  } else if (result == steps.length - 1) {
    stdout.writeln('Wizard completed successfully.');
  } else {
    stdout.writeln('Stopped on step ${result + 1}: ${steps[result]}');
  }
}


