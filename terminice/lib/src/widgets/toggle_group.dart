import '../style/theme.dart';
import '../system/focus_navigation.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

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
    if (items.isEmpty) return const {};

    // Use centralized focus navigation
    final focus = FocusNavigation(itemCount: items.length);
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

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.toggleGroup(
      onUp: () => focus.moveUp(),
      onDown: () => focus.moveDown(),
      onToggle: () => states[focus.focusedIndex] = !states[focus.focusedIndex],
      onToggleAll: () {
        final anyOff = states.any((s) => s == false);
        for (var i = 0; i < states.length; i++) {
          states[i] = anyOff;
        }
      },
      onCancel: () => cancelled = true,
    );

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: bindings,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        final gap = 2;
        final labelWidth = maxLabelWidth();

        for (var i = 0; i < items.length; i++) {
          final isFocused = focus.isFocused(i);
          final item = items[i];

          var label = item.label;
          if (label.length > labelWidth) {
            label = '${label.substring(0, labelWidth - 1)}…';
          }
          final paddedLabel = label.padRight(labelWidth);

          // Use LineBuilder for arrow and switch
          final arrow = ctx.lb.arrow(isFocused);
          final switchTxt =
              ctx.lb.switchControlHighlighted(states[i], highlight: isFocused);

          final lineCore = '$arrow $paddedLabel${' ' * gap}$switchTxt';
          ctx.gutterLine(lineCore);
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    final resultMap = <String, bool>{};
    final finalStates = (cancelled || result == PromptResult.cancelled)
        ? initialStates
        : states;
    for (var i = 0; i < items.length; i++) {
      resultMap[items[i].label] = finalStates[i];
    }
    return resultMap;
  }
}
