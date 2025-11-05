import '../lib/src/src.dart';
import 'dart:io';

void main() {
  final labels = [
    'Very poor',
    'Poor',
    'Okay',
    'Good',
    'Excellent',
  ];

  final rating = RatingPrompt(
    'Rate the experience',
    initial: 4,
    theme: PromptTheme.pastel,
    labels: labels,
  ).run();

  stdout.writeln('You rated: $rating / 5');
}
