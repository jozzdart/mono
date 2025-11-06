import '../system/rendering.dart' as style_helpers;
import '../system/framed_layout.dart';
import 'engine.dart';
import 'widget.dart';

/// Single line of text (already styled if desired).
class Text extends Widget {
  final String text;
  final bool withGutter;
  final int? maxWidth;
  const Text(this.text, {this.withGutter = true, this.maxWidth});

  @override
  Widget? buildWidget(BuildContext context) {
    final width = maxWidth ?? context.terminalColumns;
    final printable = _MultiLineWrapPrintable(text, width);
    if (withGutter) {
      return PrintableWidget(_WithGutterPrintable(printable));
    } else {
      return PrintableWidget(printable);
    }
  }
}

/// Backwards-compatible alias.
class TextLine extends Text {
  const TextLine(super.text);
}

/// Vertical group of widgets rendered in order.
class Column extends Widget {
  final List<Widget> children;
  const Column(this.children);

  @override
  void build(BuildContext context) {
    for (final c in children) {
      context.widget(c);
    }
  }
}

/// Applies the themed gutter prefix to every produced line from [child].
class Gutter extends Widget {
  final Widget child;
  const Gutter(this.child);

  @override
  Widget? buildWidget(BuildContext context) =>
      PrintableWidget(_GutterPrintable(child));
}

/// Section header line using shared styling.
class SectionHeaderLine extends Widget {
  final String name;
  final bool withGutter;
  const SectionHeaderLine(this.name, {this.withGutter = true});

  @override
  Widget? buildWidget(BuildContext context) {
    final header = style_helpers.sectionHeader(context.theme, name);
    return PrintableWidget(_LinePrintable(header, gutter: withGutter));
  }
}

/// Metric line: "Label: Value" with optional color, optionally with gutter.
class MetricLine extends Widget {
  final String label;
  final String value;
  final String? color;
  final bool withGutter;
  const MetricLine(this.label, this.value,
      {this.color, this.withGutter = true});

  @override
  Widget? buildWidget(BuildContext context) {
    final m = style_helpers.metric(context.theme, label, value, color: color);
    return PrintableWidget(_LinePrintable(m, gutter: withGutter));
  }
}

/// Frame widget: renders a title bar and optional bottom border around [child].
///
/// The [child] is expected to output lines that already include gutters if
/// desired. To apply gutters, wrap [child] with [Gutter].
class Frame extends Widget {
  final String title;
  final Widget child;

  const Frame(this.title, this.child);

  @override
  Widget? buildWidget(BuildContext context) {
    final frame = FramedLayout(title, theme: context.theme);
    final top = '${context.theme.bold}${frame.top()}${context.theme.reset}';
    final items = <Widget>[
      PrintableWidget(_LinePrintable(top)),
      child,
    ];
    if (context.theme.style.showBorder) {
      items.add(PrintableWidget(_LinePrintable(frame.bottom())));
    }
    return Column(items);
  }
}

/// Horizontal divider line.
class DividerLine extends Widget {
  final int? width; // if null, use context.terminalColumns - minimal padding
  final bool withGutter;
  const DividerLine({this.width, this.withGutter = true});

  @override
  Widget? buildWidget(BuildContext context) {
    final w = (width ?? (context.terminalColumns - 4)).clamp(4, 2000);
    final line = '${context.theme.gray}${'─' * w}${context.theme.reset}';
    return PrintableWidget(_LinePrintable(line, gutter: withGutter));
  }
}

/// Title line with bold accent, optionally underlined.
class TitleLine extends Widget {
  final String text;
  final bool underline;
  final bool withGutter;
  const TitleLine(this.text, {this.underline = false, this.withGutter = true});

  @override
  Widget? buildWidget(BuildContext context) {
    final title =
        '${context.theme.accent}${context.theme.bold}$text${context.theme.reset}';
    final widgets = <Widget>[
      PrintableWidget(_LinePrintable(title, gutter: withGutter)),
    ];
    if (underline) {
      final u =
          '${context.theme.gray}${'─' * (text.length + 2)}${context.theme.reset}';
      widgets.add(PrintableWidget(_LinePrintable(u, gutter: withGutter)));
    }
    return Column(widgets);
  }
}

class _LinePrintable implements Printable {
  final String line;
  final bool gutter;
  const _LinePrintable(this.line, {this.gutter = false});
  @override
  void render(RenderEngine engine) {
    if (gutter) {
      engine.withGutter(() => engine.writeLine(line));
    } else {
      engine.writeLine(line);
    }
  }
}

class _GutterPrintable implements Printable {
  final Printable child;
  const _GutterPrintable(this.child);
  @override
  void render(RenderEngine engine) {
    engine.withGutter(() => child.render(engine));
  }
}

class _WithGutterPrintable implements Printable {
  final Printable inner;
  const _WithGutterPrintable(this.inner);
  @override
  void render(RenderEngine engine) {
    engine.withGutter(() => inner.render(engine));
  }
}

class _MultiLineWrapPrintable implements Printable {
  final String text;
  final int width;
  const _MultiLineWrapPrintable(this.text, this.width);
  @override
  void render(RenderEngine engine) {
    // Simple wrap using engine context color setting.
    final s = text;
    int visibleLen = engine.context.colorEnabled
        ? s.runes.length
        : s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '').runes.length;
    if (visibleLen <= width) {
      engine.writeLine(s);
      return;
    }
    // Fallback naive wrap per width without breaking ANSI sequences.
    final units = s.codeUnits;
    var i = 0;
    var col = 0;
    var buf = StringBuffer();
    while (i < units.length) {
      final ch = units[i];
      final isEsc = ch == 27; // ESC
      if (isEsc) {
        final start = i;
        i++;
        while (i < units.length && units[i] != 109) {
          i++; // 'm'
        }
        if (i < units.length) i++;
        buf.write(String.fromCharCodes(units.getRange(start, i)));
        continue;
      }
      if (col >= width) {
        engine.writeLine(buf.toString());
        buf = StringBuffer();
        col = 0;
      }
      buf.writeCharCode(ch);
      col++;
      i++;
    }
    if (buf.isNotEmpty) engine.writeLine(buf.toString());
  }
}
