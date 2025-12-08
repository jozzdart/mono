import 'package:terminice/terminice.dart';

void main() {
  final prompt = TextPrompt(
    prompt: 'Enter your username',
    placeholder: 'Type something...',
    theme: PromptTheme.fire,
    validator: (input) {
      if (input.length < 3) return 'Must be at least 3 characters long.';
      return '';
    },
  );

  final result = prompt.run();

  if (result == null) {
    print('❌ Cancelled');
  } else {
    print('✅ You entered: $result');
  }
}
