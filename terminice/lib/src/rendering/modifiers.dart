import '../system/rendering.dart' as style_helpers;
import 'context.dart';
import '../style/theme.dart';
import 'widget.dart';
import 'engine.dart';

abstract class WriteModifier {
  String apply(String line, RenderContext context);
}

class GutterModifier extends WriteModifier {
  final PromptTheme theme;
  GutterModifier(this.theme);
  @override
  String apply(String line, RenderContext context) {
    return style_helpers.gutterLine(theme, line);
  }
}

class LeftPaddingModifier extends WriteModifier {
  final int spaces;
  LeftPaddingModifier(this.spaces);
  @override
  String apply(String line, RenderContext context) => (' ' * spaces) + line;
}

enum AlignMode { left, center, right }

class AlignModifier extends WriteModifier {
  final int columns;
  final AlignMode mode;
  AlignModifier(this.columns, this.mode);
  @override
  String apply(String line, RenderContext context) {
    final len = line.runes.length;
    if (mode == AlignMode.left || len >= columns) return line;
    int leftPad = 0;
    if (mode == AlignMode.center) {
      leftPad = ((columns - len) ~/ 2).clamp(0, columns);
    } else if (mode == AlignMode.right) {
      leftPad = (columns - len).clamp(0, columns);
    }
    return '${' ' * leftPad}$line';
  }
}

class ModifierScopePrintable implements Printable {
  final WriteModifier Function(RenderEngine engine) create;
  final Widget child;
  final Map<Type, Object> inherited;
  ModifierScopePrintable(this.create, this.child, this.inherited);
  @override
  void render(RenderEngine engine) {
    final mod = create(engine);
    engine.push(mod);
    try {
      child.renderWithInherited(engine, inherited);
    } finally {
      engine.pop(mod);
    }
  }
}
