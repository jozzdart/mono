import '../system/rendering.dart' as style_helpers;
import '../system/framed_layout.dart';
import 'engine.dart';
import 'widget.dart';
import 'render/widgets.dart' as ro;
import 'render/object.dart';
import 'render/box.dart' as rbox;

/// Single line of text (already styled if desired).
class Text extends ro.LeafRenderObjectWidget {
  final String text;
  final bool withGutter;
  final int? maxWidth;
  const Text(this.text, {this.withGutter = true, this.maxWidth});

  @override
  RenderObject createRenderObject(BuildContext context) {
    // Width is handled by constraints; we pass raw ANSI string
    return rbox.RenderParagraph(text);
  }
}

/// Backwards-compatible alias.
class TextLine extends Text {
  const TextLine(super.text);
}

/// Vertical group of widgets rendered in order.
class Column extends ro.MultiChildRenderObjectWidget {
  const Column({required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      rbox.RenderFlex(rbox.Axis.vertical);
}

/// Applies the themed gutter prefix to every produced line from [child].
class Gutter extends ro.SingleChildRenderObjectWidget {
  const Gutter({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => rbox.RenderGutter();
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
    return Column(children: items);
  }
}

/// Horizontal divider line.
class DividerLine extends ro.LeafRenderObjectWidget {
  final int? width; // if null, use context.terminalColumns - minimal padding
  final bool withGutter;
  const DividerLine({this.width, this.withGutter = true});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      rbox.RenderDivider(width: width);
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
    return Column(children: widgets);
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

// Gutter handled by RenderGutter above
