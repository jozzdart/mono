import 'package:terminice/terminice.dart';

Future<void> main() async {
  final wizard = Wizard(
    title: 'Project Wizard',
    theme: PromptTheme.pastel,
    steps: [
      WizardStep(
        id: 'name',
        label: 'Project Name',
        run: (state, theme) async {
          return await TextPrompt(
            prompt: 'Enter project name',
            placeholder: 'my_app',
            theme: theme,
          ).run();
        },
      ),
      WizardStep(
        id: 'language',
        label: 'Language',
        run: (state, theme) {
          final options = ['Dart', 'Go', 'Rust', 'TypeScript'];
          final picked = SearchSelectPrompt(
            options,
            prompt: 'Choose language',
            theme: theme,
          ).run();
          return picked.isEmpty ? null : picked.first;
        },
      ),
      WizardStep(
        id: 'use_lints',
        label: 'Enable Lints',
        run: (state, theme) {
          final confirmed = ConfirmPrompt(
            label: 'Lints',
            message: 'Enable recommended lints?',
            theme: theme,
          ).run();
          return confirmed;
        },
      ),
    ],
  );

  final result = await wizard.run();
  if (result == null) {
    InfoBox('Wizard cancelled',
            type: InfoBoxType.warn, theme: PromptTheme.pastel)
        .show();
  } else {
    InfoBox.multi([
      'Name: ${result['name']}',
      'Language: ${result['language']}',
      'Lints: ${result['use_lints'] == true ? 'enabled' : 'disabled'}',
    ], title: 'Summary', theme: PromptTheme.pastel)
        .show();
  }
}
