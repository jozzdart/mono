import 'dart:io';

import '../style/theme.dart';
import 'context.dart';
import 'engine.dart';
import 'widget.dart';

/// Central renderer that takes a [Widget] tree and writes to stdout.
class TerminalRenderer {
  final Stdout out;

  TerminalRenderer({Stdout? out}) : out = out ?? stdout;

  /// Renders [root] with the provided theme using a fresh [RenderEngine].
  void renderApp(Widget root,
      {PromptTheme theme = const PromptTheme(), bool colorEnabled = true}) {
    final ctx = RenderContext.fromTerminal(
      theme: theme,
      colorEnabled: colorEnabled,
    );
    final engine = RenderEngine(
      context: ctx,
      write: (line) => out.writeln(line),
    );
    root.render(engine);
  }
}
