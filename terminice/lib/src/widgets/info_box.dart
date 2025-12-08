
import '../style/theme.dart';
import '../system/widget_frame.dart';

enum InfoBoxType { info, warn, error }

/// Display messages in bordered, colorized boxes.
///
/// Aligns with ThemeDemo styling: uses themed title borders and
/// left gutter with the theme's vertical border glyph.
///
/// ```dart
/// // Fluent API
/// InfoBox('Message').withFireTheme().show();
///
/// // With shared config
/// InfoBox('Message').show();
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
  /// - A direct [theme] parameter (for convenience)
  InfoBox(
    String message, {
    this.type = InfoBoxType.info,
    this.title,
    this.theme = PromptTheme.dark,
  }) : lines = [message];

  /// Creates an info box with multiple messages.
  InfoBox.multi(
    List<String> messages, {
    this.type = InfoBoxType.info,
    this.title,
    this.theme = PromptTheme.dark,
  }) : lines = messages;

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
/// ```dart
/// infoBox('Message');
/// ```
void infoBox(
  String message, {
  InfoBoxType type = InfoBoxType.info,
  String? title,
  PromptTheme theme = PromptTheme.dark,
}) {
  InfoBox(message, type: type, title: title, theme: theme).show();
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
