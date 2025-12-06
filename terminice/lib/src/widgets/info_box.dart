import '../style/theme.dart';
import '../system/widget_frame.dart';

enum InfoBoxType { info, warn, error }

/// Display messages in bordered, colorized boxes.
///
/// Aligns with ThemeDemo styling: uses themed title borders and
/// left gutter with the theme's vertical border glyph.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// InfoBox('Message').withFireTheme().show();
/// ```
class InfoBox with Themeable {
  final List<String> lines;
  final InfoBoxType type;
  @override
  final PromptTheme theme;
  final String? title;

  InfoBox(
    String message, {
    this.type = InfoBoxType.info,
    this.theme = PromptTheme.dark,
    this.title,
  }) : lines = [message];

  InfoBox.multi(
    List<String> messages, {
    this.type = InfoBoxType.info,
    this.theme = PromptTheme.dark,
    this.title,
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
void infoBox(
  String message, {
  InfoBoxType type = InfoBoxType.info,
  PromptTheme theme = PromptTheme.dark,
  String? title,
}) {
  InfoBox(message, type: type, theme: theme, title: title).show();
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
