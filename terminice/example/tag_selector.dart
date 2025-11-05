import '../lib/src/src.dart';

void main() {
  final tags = [
    'flutter',
    'dart',
    'cli',
    'terminal',
    'ux',
    'design',
    'productivity',
    'open-source',
    'tools',
    'testing',
    'ci',
    'performance',
    'security',
    'docs',
    'release',
  ];

  final selector = TagSelector(
    tags,
    prompt: 'Pick your favorite topics',
    theme: PromptTheme.pastel,
    maxContentWidth: 56,
  );

  final chosen = selector.run();
  if (chosen.isEmpty) {
    print('No tags selected.');
  } else {
    print('Selected: ${chosen.join(', ')}');
  }
}


