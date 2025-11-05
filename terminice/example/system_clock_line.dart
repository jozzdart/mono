import '../lib/src/src.dart';

void main() {
  final now = DateTime.now();

  final items = [
    CronEvent('Rotate logs', now.add(const Duration(minutes: 3)), source: 'ops'),
    CronEvent('Backup database', now.add(const Duration(minutes: 12)), source: 'backup'),
    CronEvent('Reindex search', now.add(const Duration(minutes: 25)), source: 'search'),
    CronEvent('Purge caches', now.add(const Duration(minutes: 33)), source: 'cache'),
    CronEvent('Sync metrics', now.add(const Duration(minutes: 47)), source: 'metrics'),
  ];

  final clock = SystemClockLine(
    items,
    theme: PromptTheme.pastel,
    title: 'System Clock',
    window: const Duration(hours: 2),
  );

  clock.run();
}


