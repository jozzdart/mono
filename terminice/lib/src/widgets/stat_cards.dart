import '../style/theme.dart';
import '../system/widget_frame.dart';

/// StatCards – big numeric highlights (e.g., "✔ Tests: 98%")
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Emphasizes values using selection color and bold
class StatCards {
  final List<StatCardItem> items;
  final PromptTheme theme;
  final String? title;

  StatCards({
    required this.items,
    this.theme = const PromptTheme(),
    this.title,
  });

  void show() {
    final label = title == null || title!.isEmpty ? 'Stats' : title!;
    final frame = WidgetFrame(title: label, theme: theme);
    frame.show((ctx) {
      for (final item in items) {
        final icon =
            (item.icon == null || item.icon!.isEmpty) ? '✔' : item.icon!;
        ctx.statItem(
          item.label,
          item.value,
          icon: icon,
          tone: _toStatTone(item.tone),
        );
      }
    });
  }
}

/// Tone for a stat card: influences the icon color.
enum StatCardTone { info, warn, error, accent }

class StatCardItem {
  final String label;
  final String value;
  final String? icon; // e.g., '✔', '⚠', '⏱'
  final StatCardTone tone;

  const StatCardItem({
    required this.label,
    required this.value,
    this.icon,
    this.tone = StatCardTone.accent,
  });
}

StatTone _toStatTone(StatCardTone t) {
  switch (t) {
    case StatCardTone.info:
      return StatTone.info;
    case StatCardTone.warn:
      return StatTone.warn;
    case StatCardTone.error:
      return StatTone.error;
    case StatCardTone.accent:
      return StatTone.accent;
  }
}

/// Convenience function mirroring the requested API name.
void statCards(
  List<StatCardItem> items, {
  PromptTheme theme = const PromptTheme(),
  String? title,
}) {
  StatCards(items: items, theme: theme, title: title).show();
}
