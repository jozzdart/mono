import '../lib/src/src.dart';

void main() {
  final picker = ColorPickerPrompt(
    label: 'Theme-aligned Color Picker',
    theme: PromptTheme.pastel,
    initialHex: '#FF6A00',
  );

  final hex = picker.run();
  print('Selected: ' + (hex ?? 'cancelled'));
}
