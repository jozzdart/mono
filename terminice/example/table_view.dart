import '../lib/src/src.dart';

void main() {
  final table = TableView(
    'Project Metrics',
    columns: ['Package', 'Coverage', 'Build Time', 'Size (KB)'],
    rows: [
      ['mono_core', '92%', '00:34', '312'],
      ['mono_cli', '88%', '00:29', '204'],
      ['terminice', '95%', '00:41', '156'],
      ['mono', '—', '—', '—'],
    ],
    columnAlignments: const [
      TableAlign.left,
      TableAlign.center,
      TableAlign.right,
      TableAlign.right,
    ],
    theme: PromptTheme.pastel,
  );

  table.run();
}


