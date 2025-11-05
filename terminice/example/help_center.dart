import '../lib/src/src.dart';

void main() {
  final docs = <HelpDoc>[
    const HelpDoc(
      id: 'getting-started',
      title: 'Getting Started',
      category: 'Basics',
      content: 'Welcome to Help Center!\n\n'
          'Use the search to find topics.\n'
          'Navigate results with arrows.\n'
          'Select to preview details.\n\n'
          'This viewer respects your chosen terminal theme.',
    ),
    const HelpDoc(
      id: 'keyboard',
      title: 'Keyboard Shortcuts',
      category: 'Reference',
      content: 'Common controls:\n'
          '- Type: search\n'
          '- ↑/↓: navigate results\n'
          '- ←/→: scroll preview\n'
          '- Backspace: erase\n'
          '- Enter: confirm\n'
          '- Esc: cancel',
    ),
    const HelpDoc(
      id: 'themes',
      title: 'Themes and Styling',
      category: 'Appearance',
      content: 'The Help Center aligns with Theme Demo styling.\n'
          'Try PromptTheme.matrix, .fire, or .pastel to preview variations.',
    ),
    const HelpDoc(
      id: 'search',
      title: 'Search Tips',
      category: 'Tips',
      content: 'Search matches in both titles and content.\n'
          'Use specific keywords for best results.',
    ),
  ];

  final viewer = HelpCenter(
    docs: docs,
    title: 'Help Center',
    theme: PromptTheme.dark,
    maxVisibleResults: 8,
  );

  final selected = viewer.run();
  if (selected == null) {
    print('Cancelled.');
  } else {
    print('Selected: ' + selected.id + ' (' + selected.title + ')');
  }
}


