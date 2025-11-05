import '../lib/src/src.dart';

void main() {
  final nav = PathNavigator(
    label: 'Choose a folder',
    theme: PromptTheme.pastel, // aligns with ThemeDemo aesthetics
    showHidden: false,
    allowFiles: false, // set to true to allow selecting files
  );

  final result = nav.run();
  if (result.isEmpty) {
    print('Navigation cancelled.');
  } else {
    print('Selected path: ' + result);
  }
}


