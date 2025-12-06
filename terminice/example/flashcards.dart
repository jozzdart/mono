import 'package:terminice/terminice.dart';

void main() {
  final cards = <CardItem>[
    CardItem(
      front: 'What is the capital of France?',
      back: 'Paris',
      hint: 'City of Light',
    ),
    CardItem(
      front: 'Dart: keyword to create an immutable variable?',
      back: 'const (compile-time) or final (run-time single assignment)',
      hint: 'Two options',
    ),
    CardItem(
      front: 'HTTP status 404 stands for…',
      back: 'Not Found',
    ),
    CardItem(
      front: 'Big O of binary search on sorted array?',
      back: 'O(log n)',
      hint: 'Halving',
    ),
    CardItem(
      front: 'git command to create new branch and switch?',
      back: 'git switch -c <name> (or git checkout -b <name>)',
    ),
    CardItem(
      front: 'ANSI to reset styles?',
      back: '\x1B[0m',
    ),
  ];

  Flashcards(
      cards: cards, theme: PromptTheme.pastel, title: 'Flashcards – Demo')
    ..run();
}
