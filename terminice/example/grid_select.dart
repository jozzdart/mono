import '../lib/src/src.dart';

void main() {
  final tools = [
    'Build',
    'Test',
    'Deploy',
    'Analyze',
    'Format',
    'Docs',
    'Lint',
    'Clean',
    'Bench',
    'Profile',
    'Serve',
    'Watch',
  ];

  // Single-select, responsive columns (0 = auto), default theme
  final single = GridSelectPrompt(
    tools,
    prompt: 'Choose a task',
    columns: 0,
    maxColumns: 4,
    theme: PromptTheme.dark,
  );
  final result1 = single.run();
  print('Selected: $result1');

  // Multi-select, responsive columns, pastel theme (aligns with ThemeDemo aesthetics)
  final multi = GridSelectPrompt(
    tools,
    prompt: 'Pick multiple tasks',
    columns: 0,
    maxColumns: 4,
    multiSelect: true,
    theme: PromptTheme.pastel,
  );
  final result2 = multi.run();
  print('Selected: $result2');
}
