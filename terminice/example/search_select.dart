import '../lib/src/src.dart';

void main() {
  final fruits = [
    'apple',
    'banana',
    'cherry',
    'date',
    'elderberry',
    'fig',
    'grape',
    'kiwi',
    'lemon',
    'mango',
    'nectarine',
    'orange',
    'pear',
    'plum',
    'raspberry',
    'strawberry',
    'tangerine',
    'watermelon'
  ];

  final darkPrompt = SearchSelectPrompt(
    fruits,
    prompt: 'Dark Theme (Default)',
    theme: PromptTheme.dark,
  );

  final firePrompt = SearchSelectPrompt(
    fruits,
    prompt: '🔥 Fire Theme',
    theme: PromptTheme.fire,
  );

  final pastelPrompt = SearchSelectPrompt(
    fruits,
    prompt: 'Pastel Theme',
    multiSelect: true,
    theme: PromptTheme.pastel,
  );

  darkPrompt.run();
  firePrompt.run();
  pastelPrompt.run();
}
