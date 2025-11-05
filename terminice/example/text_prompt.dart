import 'package:terminice/src/widgets/text_prompt.dart';
import 'package:terminice/src/style/theme.dart';

void main() async {
  final prompt = TextPrompt(
    prompt: 'Enter your username',
    placeholder: 'Type something...',
    theme: PromptTheme.fire,
    validator: (input) {
      if (input.length < 3) return 'Must be at least 3 characters long.';
      return '';
    },
  );

  final result = await prompt.run();

  if (result == null) {
    print('❌ Cancelled');
  } else {
    print('✅ You entered: $result');
  }
}
