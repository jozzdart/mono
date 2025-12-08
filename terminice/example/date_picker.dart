import 'package:terminice/terminice.dart';

void main() {
  final date = DatePickerPrompt(
    label: 'Select a date',
    theme: PromptTheme.fire,
  ).run();

  print(date);
}
