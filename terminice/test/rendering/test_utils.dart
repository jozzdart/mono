import 'package:terminice/src/rendering/src.dart';
import 'package:terminice/src/style/theme.dart';

class RenderHarness {
  /// Renders [root] using the TestRenderer and returns the produced lines.
  List<String> renderWidget(
    Widget root, {
    PromptTheme theme = const PromptTheme(),
    int columns = 80,
    bool colorEnabled = true,
  }) {
    final ctx = RenderContext(
      theme: theme,
      terminalColumns: columns,
      colorEnabled: colorEnabled,
    );
    final t = TestRenderer();
    t.render(root, context: ctx);
    return t.lines;
  }
}

/// Harness that mounts widgets into an Element tree so state persists across
/// renders (useful for interactive/stateful widgets like Navigator).
class ElementHarness {
  final RenderContext _ctx;
  late final BuildOwner _owner;
  late final Element _rootEl;

  ElementHarness(
    Widget root, {
    PromptTheme theme = const PromptTheme(),
    int columns = 80,
    bool colorEnabled = true,
  }) : _ctx = RenderContext(
          theme: theme,
          terminalColumns: columns,
          colorEnabled: colorEnabled,
        ) {
    _owner = BuildOwner(_ctx);
    _rootEl = _owner.mountRoot(root);
  }

  /// Renders current tree and captures output lines.
  List<String> render() {
    final lines = <String>[];
    final engine =
        RenderEngine(context: _ctx, write: (line) => lines.add(line));
    _owner.buildDirty();
    for (final p in _rootEl.outputs) {
      p.render(engine);
    }
    return lines;
  }
}

/// Utilities to normalize lines for comparison in tests.
class RenderNormalize {
  static String stripAnsi(String input) {
    final ansi = RegExp(r'\x1B\[[0-9;]*m');
    return input.replaceAll(ansi, '');
  }

  static List<String> normalizeLines(
    List<String> lines, {
    bool strip = true,
    bool trimRight = true,
  }) {
    return lines.map((l) {
      var s = l;
      if (strip) s = stripAnsi(s);
      if (trimRight) s = s.replaceAll(RegExp(r'\s+$'), '');
      return s;
    }).toList();
  }
}
