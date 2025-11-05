import '../lib/src/src.dart';

void main() {
  final tasks = <TodoTask>[
    const TodoTask('Ship 1.0', tags: ['release', 'urgent'], priority: TodoPriority.high),
    const TodoTask('Write docs', tags: ['docs'], priority: TodoPriority.medium),
    const TodoTask('Fix flaky test', tags: ['test', 'bug'], priority: TodoPriority.high),
    const TodoTask('Refactor CLI parser', tags: ['tech-debt'], priority: TodoPriority.low),
    const TodoTask('Polish theme demo', tags: ['design'], priority: TodoPriority.medium),
  ];

  final dashboard = TodoDashboard(
    'Todo Dashboard',
    tasks: tasks,
    availableTags: const [
      'urgent',
      'release',
      'docs',
      'bug',
      'feature',
      'design',
      'test',
      'tech-debt',
    ],
    theme: PromptTheme.pastel,
  );

  // Run interactively. The returned list contains final edits.
  final _ = dashboard.run();
}


