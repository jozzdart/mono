import 'package:terminice/terminice.dart';

void main() {
  final date = DateFieldsPrompt(
    label: 'Your birthday',
    theme: PromptTheme.fire,
  ).run();

  print(date);
}
