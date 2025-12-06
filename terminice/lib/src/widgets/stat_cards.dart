import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/prompt_runner.dart';

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
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    final style = theme.style;

    final label = title == null || title!.isEmpty ? 'Stats' : title!;
    final frame = FramedLayout(label, theme: theme);
    out.writeln('${theme.bold}${frame.top()}${theme.reset}');

    for (final item in items) {
      final toneColor = _colorFor(item.tone, theme);
      final icon = (item.icon == null || item.icon!.isEmpty) ? '✔' : item.icon!;

      final line = StringBuffer();
      line.write('${theme.gray}${style.borderVertical}${theme.reset} ');
      line.write('$toneColor$icon${theme.reset} ');
      line.write('${theme.dim}${item.label}:${theme.reset} ');
      line.write('${theme.selection}${theme.bold}${item.value}${theme.reset}');

      out.writeln(line.toString());
    }

    if (style.showBorder) {
      out.writeln(frame.bottom());
    }
  }
}

/// Tone for a stat card: influences the icon color.
enum StatTone { info, warn, error, accent }

class StatCardItem {
  final String label;
  final String value;
  final String? icon; // e.g., '✔', '⚠', '⏱'
  final StatTone tone;

  const StatCardItem({
    required this.label,
    required this.value,
    this.icon,
    this.tone = StatTone.accent,
  });
}

String _colorFor(StatTone t, PromptTheme theme) {
  switch (t) {
    case StatTone.info:
      return theme.info;
    case StatTone.warn:
      return theme.warn;
    case StatTone.error:
      return theme.error;
    case StatTone.accent:
      return theme.accent;
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
