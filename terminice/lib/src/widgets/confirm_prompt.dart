import 'package:terminice/terminice.dart';

/// ConfirmPrompt – elegant confirmation dialog.
///
/// Controls:
/// - ← / → or ↑ / ↓ toggle between options
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns false)
///
/// **Example:**
/// ```dart
/// final confirmed = ConfirmPrompt(
///   label: 'Delete',
///   message: 'Are you sure you want to delete?',
/// ).withFireTheme().run();
///
/// if (confirmed) {
///   // User selected Yes
/// }
/// ```
class ConfirmPrompt with Themeable {
  final String label;
  final String message;
  final String yesLabel;
  final String noLabel;
  final bool defaultYes;

  @override
  final PromptTheme theme;

  /// Creates a confirm prompt.
  ConfirmPrompt({
    required this.label,
    required this.message,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.defaultYes = true,
    this.theme = PromptTheme.dark,
  });

  @override
  ConfirmPrompt copyWithTheme(PromptTheme theme) {
    return ConfirmPrompt(
      label: label,
      message: message,
      yesLabel: yesLabel,
      noLabel: noLabel,
      defaultYes: defaultYes,
      theme: theme,
    );
  }

  /// Runs the confirm prompt.
  ///
  /// Returns `true` if Yes selected, `false` if No selected or cancelled.
  bool run() {
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
