import 'package:terminice/terminice.dart';

void main() {
  // Try other themes: PromptTheme.dark, .matrix, .fire, .pastel
  final manager = EnvManager(
    theme: PromptTheme.pastel,
    title: 'Environment Variables',
  );

  manager.run();
}
