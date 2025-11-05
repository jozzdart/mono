import '../lib/src/src.dart';

void main() {
  final items = [
    const ChoiceMapItem('Projects', subtitle: 'Browse and manage'),
    const ChoiceMapItem('Tasks', subtitle: 'Plan and track'),
    const ChoiceMapItem('Reports', subtitle: 'Insights & charts'),
    const ChoiceMapItem('Settings', subtitle: 'Preferences'),
    const ChoiceMapItem('Marketplace', subtitle: 'Explore plugins'),
    const ChoiceMapItem('Help', subtitle: 'Docs & support'),
  ];

  final map = ChoiceMap(
    items,
    prompt: 'Dashboard',
    multiSelect: true, // try false for single select
    theme: PromptTheme.pastel,
  );

  final selection = map.run();
  if (selection.isEmpty) {
    print('Cancelled');
  } else {
    print('Selected: ' + selection.join(', '));
  }
}
