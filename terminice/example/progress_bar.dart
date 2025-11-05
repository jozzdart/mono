import '../lib/src/src.dart';

void main() {
  final pb = ProgressBar(
    'Downloading Assets',
    total: 120,
    width: 40,
    totalDuration: const Duration(seconds: 3),
    theme: PromptTheme.pastel,
  );
  pb.run();

  final fb = ProgressBar(
    'Downloading Assets',
    total: 120,
    width: 40,
    totalDuration: const Duration(seconds: 3),
    theme: PromptTheme.fire,
  );
  fb.run();

  final mb = ProgressBar(
    'Downloading Assets',
    total: 120,
    width: 40,
    totalDuration: const Duration(seconds: 3),
    theme: PromptTheme.matrix,
  );
  mb.run();

  final dp = ProgressBar(
    'Downloading Assets',
    total: 120,
    width: 40,
    totalDuration: const Duration(seconds: 3),
    theme: PromptTheme.dark,
  );
  dp.run();
}
