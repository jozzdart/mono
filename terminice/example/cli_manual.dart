import '../lib/src/src.dart';

void main() {
  final pages = <ManualPage>[
    ManualPage(
      name: 'mono',
      section: '1',
      synopsis: 'mono <command> [options]',
      description:
          'Mono is a workspace CLI for managing projects, running tasks, and visualizing health.',
      options: const [
        ManualOption(flag: '-h, --help', description: 'Show help information.'),
        ManualOption(flag: '-v, --version', description: 'Print version and exit.'),
        ManualOption(flag: '--debug', description: 'Enable verbose logging output.'),
      ],
      examples: const [
        'mono list                       # list projects',
        'mono task test --all           # run tests in all projects',
        'mono graph                     # show dependency graph',
      ],
      seeAlso: const ['mono help', 'mono task', 'mono list'],
    ),
    ManualPage(
      name: 'terminice',
      section: '7',
      synopsis: 'terminice [widgets]',
      description:
          'Terminice is a collection of beautiful terminal widgets that adhere to a cohesive theme. Use them to build rich TUI experiences.',
      options: const [
        ManualOption(flag: '--theme=<name>', description: 'Set style theme: dark, matrix, fire, pastel.'),
      ],
      examples: const [
        'dart example/theme_demo.dart',
        'dart example/cli_manual.dart',
      ],
      seeAlso: const ['help_center(7)', 'cheat_sheet(7)'],
    ),
  ];

  final manual = CLIManual(
    pages: pages,
    title: 'CLI Manual',
    theme: PromptTheme.dark,
  );

  manual.run();
}


