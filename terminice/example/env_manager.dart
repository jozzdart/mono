import 'package:terminice/terminice.dart';

Future<void> main() async {
  // Try other themes: PromptTheme.dark, .matrix, .fire, .pastel
  final manager = EnvManager(
    theme: PromptTheme.pastel,
    title: 'Environment Variables',
  );

  await manager.run();
}


