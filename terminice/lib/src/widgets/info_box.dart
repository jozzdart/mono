import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';

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
    final style = theme.style;

    final label = title ?? _defaultTitle(type);
    final content = lines.isEmpty ? const <String>[] : lines;

    final statusColor = _colorFor(type, theme);
    final top = style.showBorder
        ? FrameRenderer.titleWithBordersColored(label, theme, statusColor)
        : FrameRenderer.plainTitleColored(label, theme, statusColor);
    stdout.writeln('${theme.bold}$top${theme.reset}');

    for (final line in content) {
      stdout.writeln(
          '$statusColor${style.borderVertical}${theme.reset} $statusColor$line${theme.reset}');
    }

    if (style.showBorder) {
      stdout
          .writeln(FrameRenderer.bottomLineColored(label, theme, statusColor));
    }
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

String _colorFor(InfoBoxType t, PromptTheme theme) {
  switch (t) {
    case InfoBoxType.info:
      return theme.info;
    case InfoBoxType.warn:
      return theme.warn;
    case InfoBoxType.error:
      return theme.error;
  }
}
