import 'package:terminice/terminice.dart';

void main() {
  final file = FilePickerPrompt(
    label: 'Select a file',
    theme: PromptTheme.fire,
  ).run();

  print(file);
}
