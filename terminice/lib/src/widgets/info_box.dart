import '../style/theme.dart';
import '../system/widget_frame.dart';

enum InfoBoxType { info, warn, error }

/// Display messages in bordered, colorized boxes.
///
/// Aligns with ThemeDemo styling: uses themed title borders and
/// left gutter with the theme's vertical border glyph.
class InfoBox {
  final List<String> lines;
  final InfoBoxType type;
  final PromptTheme theme;
  final String? title;

  InfoBox(
    String message, {
    this.type = InfoBoxType.info,
    this.theme = const PromptTheme(),
    this.title,
  }) : lines = [message];

  InfoBox.multi(
    List<String> messages, {
    this.type = InfoBoxType.info,
    this.theme = const PromptTheme(),
    this.title,
  }) : lines = messages;

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
  PromptTheme theme = const PromptTheme(),
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
