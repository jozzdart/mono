import 'package:terminice/src/widgets/date_picker.dart';
import 'package:terminice/src/style/theme.dart';

void main() {
  final date = DatePickerPrompt(
    label: 'Select a date',
    theme: PromptTheme.fire,
  ).run();

  print(date);
}
