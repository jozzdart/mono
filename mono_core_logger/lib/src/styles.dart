import 'package:mono_core_logger/mono_core_logger.dart';

/// Semantic style tokens (actual colors/styles are implementation-defined).
enum StyleToken {
  primary,
  success,
  warning,
  error,
  muted,
  accent,
  dim,
  bold,
  italic,
  underline,
}

class StyledText {
  final String text;
  final Set<StyleToken> tokens;
  const StyledText(this.text, [this.tokens = const <StyleToken>{}]);
}

/// Theme interface for mapping log semantics to style tokens.
abstract class StyleTheme {
  Set<StyleToken> stylesForLevel(LogLevel level);
  Set<StyleToken> stylesForCategory(String category) => const <StyleToken>{};
}
