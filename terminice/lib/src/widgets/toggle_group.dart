import 'dart:io';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

/// ToggleGroup – manage multiple on/off toggles with elegant keyboard flipping.
///
/// Controls:
/// - ↑ / ↓ navigate between rows
/// - ← / → or Space toggles the focused switch
/// - A toggles all
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns initial states)
class ToggleItem {
  final String label;
  final bool initialOn;

  const ToggleItem(this.label, {this.initialOn = false});
}

class ToggleGroup {
  final String title;
  final List<ToggleItem> items;
  final PromptTheme theme;

  /// Align rows to a computed content width (does not expand to terminal).
  final bool alignContent;

  ToggleGroup(
    this.title,
    this.items, {
    this.theme = PromptTheme.dark,
    this.alignContent = true,
  });

  /// Returns a map of label -> on/off after confirmation.
  /// If cancelled, returns the original initial states.
  Map<String, bool> run() {
    final style = theme.style;
    if (items.isEmpty) return const {};

    int focused = 0;
    bool cancelled = false;
    final states = List<bool>.generate(items.length, (i) => items[i].initialOn);
    final initialStates = List<bool>.from(states);

    int maxLabelWidth() {
      var w = 0;
      for (final it in items) {
        final len = it.label.length;
        if (len > w) w = len;
      }
      if (w < 8) w = 8;
      if (w > 48) w = 48; // cap for tidy layout
      return w;
    }

    String switchControl(bool on, {bool highlighted = false}) {
      // Render a themed switch-like control using ASCII-only glyphs
      final left = on ? theme.checkboxOn : theme.checkboxOff;
      final sym = on ? style.checkboxOnSymbol : style.checkboxOffSymbol;
      final text = on ? ' ON ' : ' OFF';
      final body = '$sym$text';
      final colored = '$left$body${theme.reset}';
      if (highlighted && style.useInverseHighlight) {
        return '${theme.inverse}$colored${theme.reset}';
      }
      return colored;
    }

    void render() {
      Terminal.clearAndHome();

      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      if (style.boldPrompt) stdout.writeln('${theme.bold}$top${theme.reset}');

      if (style.showBorder) {
        stdout.writeln(frame.connector());
      }

      final leftPrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      final gap = 2;
      final labelWidth = maxLabelWidth();

      for (var i = 0; i < items.length; i++) {
        final isFocused = i == focused;
        final item = items[i];

        var label = item.label;
        if (label.length > labelWidth) {
          label = '${label.substring(0, labelWidth - 1)}…';
        }
        final paddedLabel = label.padRight(labelWidth);

        final arrow =
            isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final switchTxt = switchControl(states[i], highlighted: isFocused);

        final lineCore = '$arrow $paddedLabel';
        stdout.writeln('$leftPrefix$lineCore${' ' * gap}$switchTxt');
      }

      if (style.showBorder) {
        stdout.writeln(frame.bottom());
      }

      frame.printHintsGrid([
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('←/→ / Space', theme), 'toggle'],
        [Hints.key('A', theme), 'toggle all'],
        [Hints.key('Enter', theme), 'confirm'],
        [Hints.key('Esc', theme), 'cancel'],
      ]);

      Terminal.hideCursor();
    }

    int moveUp(int i) => (i - 1 + items.length) % items.length;
    int moveDown(int i) => (i + 1) % items.length;

    void toggle(int i) {
      states[i] = !states[i];
    }

    void toggleAll() {
      final anyOff = states.any((s) => s == false);
      for (var i = 0; i < states.length; i++) {
        states[i] = anyOff; // if any off, turn all on; else turn all off
      }
    }

    final term = Terminal.enterRaw();
    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    render();
    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.enter) break;
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.arrowUp) {
          focused = moveUp(focused);
        } else if (ev.type == KeyEventType.arrowDown) {
          focused = moveDown(focused);
        } else if (ev.type == KeyEventType.arrowLeft ||
            ev.type == KeyEventType.arrowRight ||
            ev.type == KeyEventType.space) {
          toggle(focused);
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          if (ch.toLowerCase() == 'a') toggleAll();
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    final result = <String, bool>{};
    final finalStates = cancelled ? initialStates : states;
    for (var i = 0; i < items.length; i++) {
      result[items[i].label] = finalStates[i];
    }
    return result;
  }
}
