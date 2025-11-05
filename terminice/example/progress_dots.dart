import '../lib/src/src.dart';

void main() {
  ProgressDots(
    'Loading',
    message: 'Please wait',
    theme: PromptTheme.pastel,
    duration: const Duration(seconds: 3),
    interval: const Duration(milliseconds: 240),
  ).run();
}
