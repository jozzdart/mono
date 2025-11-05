import 'package:terminice/src/widgets/file_pickers.dart';
import 'package:terminice/src/style/theme.dart';

void main() {
  final file = FilePickerPrompt(
    label: 'Select a file',
    theme: PromptTheme.fire,
  ).run();

  print(file);
}
