import 'package:terminice/terminice.dart';

void main() {
  // Try other themes: PromptTheme.dark, .matrix, .fire, .pastel
  final dashboard = SystemDashboard(
    theme: PromptTheme.dark,
    refresh: const Duration(milliseconds: 300),
    barWidth: 36,
    diskMount: '/',
  );

  dashboard.run();
}
