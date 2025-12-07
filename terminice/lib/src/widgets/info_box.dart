import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/widget_frame.dart';

enum InfoBoxType { info, warn, error }

/// Display messages in bordered, colorized boxes.
///
/// Aligns with ThemeDemo styling: uses themed title borders and
/// left gutter with the theme's vertical border glyph.
///
/// **Configuration:** Supports both direct theme and [PromptConfig]:
/// ```dart
/// // Fluent API
/// InfoBox('Message').withFireTheme().show();
///
/// // With shared config
/// final config = PromptConfig.fire;
/// InfoBox('Message', config: config).show();
/// ```
class InfoBox with Themeable {
  final List<String> lines;
  final InfoBoxType type;
  @override
  final PromptTheme theme;
  final String? title;

  /// Creates an info box with a single message.
  ///
  /// Accepts either:
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  InfoBox(
    String message, {
    this.type = InfoBoxType.info,
    this.title,
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  })  : lines = [message],
        theme = config?.theme ?? theme;

  /// Creates an info box with multiple messages.
  ///
  /// Accepts either:
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  InfoBox.multi(
    List<String> messages, {
    this.type = InfoBoxType.info,
    this.title,
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  })  : lines = messages,
        theme = config?.theme ?? theme;

  InfoBox._internal({
    required this.lines,
    required this.type,
    required this.theme,
    this.title,
  });

  @override
  InfoBox copyWithTheme(PromptTheme theme) {
    return InfoBox._internal(
      lines: lines,
      type: type,
      theme: theme,
      title: title,
    );
  }

  /// Render the box to stdout.
  void show() {
    final label = title ?? _defaultTitle(type);
    final frame = WidgetFrame(title: label, theme: theme);
    frame.show((ctx) {
      final tone = _toStatTone(type);
      final icon = _iconFor(type);
      for (final line in lines) {
        ctx.styledMessage(line, icon: icon, tone: tone);
      }
    });
  }
}

/// Convenience function mirroring the requested API name.
///
/// Supports [PromptConfig] for shared configuration:
/// ```dart
/// final config = PromptConfig.matrix;
/// infoBox('Message', config: config);
/// ```
void infoBox(
  String message, {
  InfoBoxType type = InfoBoxType.info,
  String? title,
  PromptConfig? config,
  PromptTheme theme = PromptTheme.dark,
}) {
  InfoBox(message, type: type, title: title, config: config, theme: theme)
      .show();
}

String _defaultTitle(InfoBoxType t) {
  switch (t) {
    case InfoBoxType.info:
      return 'Info';
    case InfoBoxType.warn:
      return 'Warning';
    case InfoBoxType.error:
      return 'Error';
  }
}

StatTone _toStatTone(InfoBoxType t) {
  switch (t) {
    case InfoBoxType.info:
      return StatTone.info;
    case InfoBoxType.warn:
      return StatTone.warn;
    case InfoBoxType.error:
      return StatTone.error;
  }
}

String _iconFor(InfoBoxType t) {
  switch (t) {
    case InfoBoxType.info:
      return 'ℹ';
    case InfoBoxType.warn:
      return '⚠';
    case InfoBoxType.error:
      return '✖';
  }
}
