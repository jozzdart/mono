import 'package:terminice/terminice.dart';

void main() {
  final range = RangePrompt(
    'Range',
    min: 0,
    max: 100,
    theme: PromptTheme.fire,
    step: 10,
  ).run();

  print(range);
}
