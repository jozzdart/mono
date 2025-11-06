import 'dart:io';

import '../style/theme.dart';
import 'engine.dart';
import 'widget.dart';
import 'context.dart';
import 'core/element.dart';
import 'input/key_events.dart';
import 'input/focus.dart';
import 'scheduler.dart';

/// Minimal AppHost that can rebuild the entire tree when requested.
class AppHost {
  final PromptTheme theme;
  final bool colorEnabled;
  final Stdout out;
  final Widget _root;
  BuildOwner? _owner;
  Element? _rootEl;
  final Scheduler _scheduler = Scheduler.instance;

  AppHost(this._root,
      {this.theme = const PromptTheme(), this.colorEnabled = true, Stdout? out})
      : out = out ?? stdout;

  void run() {
    _render();
  }

  void rebuild(void Function() mutateRoot) {
    mutateRoot();
    _scheduler.requestFrame(_render);
  }

  void _render() {
    final ctx =
        RenderContext.fromTerminal(theme: theme, colorEnabled: colorEnabled);
    _owner ??= BuildOwner(ctx);
    _rootEl ??= _owner!.mountRoot(_root);
    _owner!.buildDirty();
    final buffer = ScreenBuffer();
    final engine =
        RenderEngine(context: ctx, write: (line) => buffer.add(line));
    for (final p in _rootEl!.outputs) {
      p.render(engine);
    }
    buffer.flushTo((line) => out.writeln(line), clearBefore: true);
  }
}

void runApp(Widget root,
    {PromptTheme theme = const PromptTheme(), bool colorEnabled = true}) {
  AppHost(root, theme: theme, colorEnabled: colorEnabled).run();
}

/// Interactive loop: mounts the tree and dispatches key events to the current
/// focus until ESC or Ctrl+C is pressed.
void runInteractive(Widget root,
    {PromptTheme theme = const PromptTheme(), bool colorEnabled = true}) {
  final host = AppHost(root, theme: theme, colorEnabled: colorEnabled);
  host.run();
  while (true) {
    final ev = KeyEventReader.read();
    if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
      break;
    }
    FocusManager.instance.dispatch(ev);
    host.rebuild(() {});
  }
}
