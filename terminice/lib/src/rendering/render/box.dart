import '../text/utils.dart' as txt;
import '../../system/rendering.dart' as style_helpers;
import 'object.dart';
import 'painting.dart';

class RenderParagraph extends RenderBox {
  String text;
  RenderParagraph(this.text);

  @override
  void performLayout() {}

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    final width = constraints.maxWidth;
    final lines = txt.wrapAnsi(text, width);
    for (final l in lines) {
      context.writeLine(l);
    }
  }
}

class RenderFlex extends RenderContainerBox {
  final Axis direction;
  RenderFlex(this.direction);

  @override
  void performLayout() {
    for (final c in children) {
      c.layout(BoxConstraints(maxWidth: constraints.maxWidth));
    }
  }

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    for (final c in children) {
      c.paint(context);
    }
  }
}

enum Axis { horizontal, vertical }

class RenderDivider extends RenderBox {
  final int? width;
  RenderDivider({this.width});

  @override
  void performLayout() {}

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    final rc = context.renderContext;
    final w = (width ?? (rc.terminalColumns - 4)).clamp(4, 2000);
    final line = '${rc.theme.gray}${'─' * w}${rc.theme.reset}';
    context.writeLine(line);
  }
}

class RenderGutter extends RenderContainerBox {
  @override
  void performLayout() {
    for (final c in children) {
      c.layout(BoxConstraints(maxWidth: constraints.maxWidth));
    }
  }

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    final theme = context.renderContext.theme;
    final transformed = _TransformPaintContext(
        context, (line) => style_helpers.gutterLine(theme, line));
    for (final c in children) {
      c.paint(transformed);
    }
  }
}

class _TransformPaintContext extends PaintContext {
  final String Function(String) transform;
  _TransformPaintContext(PaintContext base, this.transform)
      : super(base.renderContext, base.buffer);
  @override
  void writeLine(String line) {
    super.writeLine(transform(line));
  }
}


