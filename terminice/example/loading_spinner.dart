import '../lib/src/src.dart';

void main() {
  LoadingSpinner(
    'Initializing',
    message: 'Preparing workspace',
    style: SpinnerStyle.dots,
    duration: const Duration(seconds: 2),
    fps: 14,
    theme: PromptTheme.pastel,
  ).run();

  LoadingSpinner(
    'Processing',
    message: 'Compiling assets',
    style: SpinnerStyle.bars,
    duration: const Duration(seconds: 2),
    fps: 16,
    theme: PromptTheme.fire,
  ).run();

  LoadingSpinner(
    'Finalizing',
    message: 'Almost there',
    style: SpinnerStyle.arcs,
    duration: const Duration(seconds: 2),
    fps: 12,
    theme: PromptTheme.matrix,
  ).run();
}


