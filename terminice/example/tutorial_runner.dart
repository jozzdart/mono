import '../lib/src/src.dart';

void main() {
  final runner = TutorialRunner(
    title: 'Getting Started Tutorial',
    theme: PromptTheme.pastel,
    steps: const [
      TutorialStep(
        title: 'Install dependencies',
        description: 'Run: dart pub get\nEnsures all packages are downloaded and ready.',
      ),
      TutorialStep(
        title: 'Run the tests',
        description: 'Execute: dart test\nAll tests should pass before proceeding.',
      ),
      TutorialStep(
        title: 'Launch the demo',
        description: 'Try one of the examples under the example/ folder.',
      ),
      TutorialStep(
        title: 'Explore key bindings',
        description:
            'Use arrow keys to navigate, Space to toggle completion, and R to reset progress.',
      ),
      TutorialStep(
        title: 'Finish tutorial',
        description: 'Press Enter to confirm when you are done.',
      ),
    ],
  );

  // Returns updated steps (or the original steps if cancelled)
  final result = runner.run();

  // Optionally print summary after exiting
  final done = result.where((s) => s.done).length;
  final total = result.length;
  print('Tutorial completed steps: $done/$total');
}


