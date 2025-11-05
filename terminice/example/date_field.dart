import 'package:terminice/src/widgets/date_field.dart';
import 'package:terminice/src/style/theme.dart';

void main() {
  final date = DateFieldsPrompt(
    label: 'Your birthday',
    theme: PromptTheme.fire,
  ).run();

  print(date);
}
