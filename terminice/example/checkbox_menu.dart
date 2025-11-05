import '../lib/src/src.dart';

void main() {
  final items = <String>[
    'Apples',
    'Bananas',
    'Cherries',
    'Dates',
    'Elderberries',
    'Figs',
    'Grapes',
    'Honeydew',
    'Iced Tea',
    'Jackfruit',
    'Kiwi',
    'Lime',
  ];

  final prompt = CheckboxMenu(
    label: 'Select items',
    options: items,
    theme: PromptTheme.pastel, // try .dark, .matrix, .fire, .pastel
    initialSelected: {1, 3},
  );

  final selection = prompt.run();
  if (selection.isEmpty) {
    print('No selection or cancelled.');
  } else {
    print('Selected: ' + selection.join(', '));
  }
}
