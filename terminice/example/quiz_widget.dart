import '../lib/src/src.dart';

void main() {
  final quiz = QuizWidget(
    title: 'CLI Quiz',
    theme: PromptTheme.dark,
    questions: [
      QuizQuestion(
        text: 'Which command lists files in a directory?',
        description: 'Pick the most common Unix-like command.',
        options: ['cat', 'ls', 'cd', 'touch'],
        correctIndex: 1,
      ),
      QuizQuestion(
        text: 'What does HTTP stand for?',
        options: [
          'HyperText Transfer Protocol',
          'High Transfer Text Protocol',
          'Hyperlink Transfer Process',
          'Home Tool Transfer Protocol',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        text: 'In semantic versioning, what does the first number represent?',
        options: [
          'Minor version',
          'Patch version',
          'Major version',
          'Build metadata',
        ],
        correctIndex: 2,
      ),
    ],
  );

  final result = quiz.run();
  // Optional: additional app-level handling
  print('Final score: ${result.correct}/${result.total}');
}


