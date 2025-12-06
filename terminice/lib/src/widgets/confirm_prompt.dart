import '../style/theme.dart';
import '../system/simple_prompt.dart';

/// ConfirmPrompt – elegant instant confirmation dialog (no timers or delays).
///
/// Controls:
/// - ← / → or ↑ / ↓ toggle between options
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns false)
///
/// **Implementation:** Uses [SimplePrompt] for core functionality,
/// demonstrating composition over inheritance.
///
/// **Example:**
/// ```dart
/// final confirmed = ConfirmPrompt(
///   label: 'Delete',
///   message: 'Are you sure you want to delete?',
/// ).run();
///
/// if (confirmed) {
///   // User selected Yes
/// }
/// ```
class ConfirmPrompt {
  final String label;
  final String message;
  final String yesLabel;
  final String noLabel;
  final PromptTheme theme;
  final bool defaultYes;

  ConfirmPrompt({
    required this.label,
    required this.message,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.theme = PromptTheme.dark,
    this.defaultYes = true,
  });

  bool run() {
    // Delegate to SimplePrompts.confirm for all core functionality
    return SimplePrompts.confirm(
      title: label,
      message: message,
      yesLabel: yesLabel,
      noLabel: noLabel,
      defaultYes: defaultYes,
      theme: theme,
    ).run();
  }
}
