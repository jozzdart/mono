import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/configurable.dart';
import '../system/prompt_animations.dart';
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
/// **Configuration:** Uses [Configurable] mixin for unified theme config:
/// ```dart
/// final confirmed = ConfirmPrompt(label: 'Delete', message: 'Sure?')
///   .withFireTheme()
///   .run();
/// ```
///
/// **Config Object:** Also accepts a [PromptConfig] for reusable configuration:
/// ```dart
/// final config = PromptConfig.fire;
/// ConfirmPrompt(label: 'Delete', message: 'Sure?', config: config).run();
/// ```
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
class ConfirmPrompt with Configurable {
  final String label;
  final String message;
  final String yesLabel;
  final String noLabel;
  final bool defaultYes;

  @override
  final PromptTheme theme;

  @override
  final bool animated;

  @override
  final PromptAnimations? animations;

  /// Creates a confirm prompt.
  ///
  /// Accepts either:
  /// - Individual [theme] parameter (animations not used for confirm)
  /// - A [PromptConfig] object (which takes precedence if provided)
  ConfirmPrompt({
    required this.label,
    required this.message,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.defaultYes = true,
    // Config object (preferred for reusability)
    PromptConfig? config,
    // Individual parameter (for convenience/backward compatibility)
    PromptTheme theme = PromptTheme.dark,
  })  : theme = config?.theme ?? theme,
        animated = config?.animated ?? false,
        animations = config?.animations;

  @override
  ConfirmPrompt copyWith({
    PromptTheme? theme,
    bool? animated,
    PromptAnimations? animations,
  }) {
    return ConfirmPrompt(
      label: label,
      message: message,
      yesLabel: yesLabel,
      noLabel: noLabel,
      defaultYes: defaultYes,
      theme: theme ?? this.theme,
    );
  }

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
