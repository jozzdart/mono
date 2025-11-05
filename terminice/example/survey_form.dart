import '../lib/src/src.dart';

void main() {
  final questions = <SurveyQuestionSpec>[
    SurveyQuestionSpec.text(
      name: 'name',
      prompt: 'Your name',
      placeholder: 'e.g. Alex Smith',
      validator: (v) {
        final s = (v as String).trim();
        return s.isEmpty ? 'Please enter your name' : null;
      },
    ),
    SurveyQuestionSpec.text(
      name: 'age',
      prompt: 'Your age',
      placeholder: 'numbers only',
      validator: (v) {
        final s = (v as String).trim();
        if (s.isEmpty) return 'Please enter your age';
        if (int.tryParse(s) == null) return 'Age must be a number';
        return null;
      },
    ),
    SurveyQuestionSpec.singleChoice(
      name: 'favoriteFruit',
      prompt: 'Favorite fruit',
      options: ['Apple', 'Banana', 'Cherry', 'Mango', 'Pear'],
      initialChoiceIndex: 0,
    ),
    SurveyQuestionSpec.multiChoice(
      name: 'hobbies',
      prompt: 'Hobbies',
      options: ['Reading', 'Music', 'Sports', 'Coding', 'Travel'],
    ),
    SurveyQuestionSpec.rating(
      name: 'satisfaction',
      prompt: 'Satisfaction',
      minRating: 1,
      maxRating: 5,
      initialRating: 3,
    ),
    SurveyQuestionSpec.yesNo(
      name: 'newsletter',
      prompt: 'Subscribe to newsletter',
      initialYes: true,
    ),
  ];

  final result = surveyForm(
    title: 'SurveyForm · Demo',
    questions: questions,
    theme: PromptTheme.dark,
  );

  if (result == null) {
    print('Survey cancelled');
    return;
  }

  print('Survey results:');
  result.values.forEach((k, v) => print('  $k: $v'));
}


