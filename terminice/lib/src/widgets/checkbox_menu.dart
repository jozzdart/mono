import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/widget_frame.dart';

/// CheckboxMenu – vertical multi-select checklist with live summary counter.
///
/// Controls:
/// - ↑ / ↓ navigate
/// - Space toggle selection
/// - A select all / clear all
/// - Enter confirm
/// - Esc / Ctrl+C cancel (returns empty list)
class CheckboxMenu {
  final String label;
  final List<String> options;
  final PromptTheme theme;
  final int maxVisible; // soft cap; may reduce based on terminal size
  final Set<int> initialSelected;

  CheckboxMenu({
    required this.label,
    required this.options,
    this.theme = PromptTheme.dark,
    this.maxVisible = 12,
    Set<int>? initialSelected,
  }) : initialSelected = {...(initialSelected ?? const <int>{})};

  List<String> run() {
    if (options.isEmpty) return <String>[];

    // Use centralized list navigation for selection & scrolling
    final nav = ListNavigation(
      itemCount: options.length,
      maxVisible: maxVisible,
    );

    final selected = <int>{
      ...initialSelected.where((i) => i >= 0 && i < options.length)
    };
    bool cancelled = false;

    void toggle(int index) {
      if (index < 0 || index >= options.length) return;
      if (selected.contains(index)) {
        selected.remove(index);
      } else {
        selected.add(index);
      }
    }

    void selectAllOrClear() {
      if (selected.length == options.length) {
        selected.clear();
      } else {
        selected
          ..clear()
          ..addAll(List<int>.generate(options.length, (i) => i));
      }
    }

    // Use KeyBindings for declarative, composable key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () => nav.moveUp(),
          onDown: () => nav.moveDown(),
        ) +
        KeyBindings.toggle(
          onToggle: () => toggle(nav.selectedIndex),
          hintDescription: 'toggle',
        ) +
        KeyBindings.letter(
          char: 'A',
          onPress: selectAllOrClear,
          hintDescription: 'select all / clear',
        ) +
        KeyBindings.prompt(
          onCancel: () => cancelled = true,
        );

    String summaryLine() {
      final total = options.length;
      final count = selected.length;
      if (count == 0) {
        return '${theme.dim}(none selected)${theme.reset}';
      }
      // render up to 3 selections by label, then "+N"
      final indices = selected.toList()..sort();
      final names = <String>[];
      for (var i = 0; i < indices.length && i < 3; i++) {
        final name = options[indices[i]];
        names.add('${theme.accent}$name${theme.reset}');
      }
      final more = indices.length > 3
          ? ' ${theme.dim}(+${indices.length - 3})${theme.reset}'
          : '';
      return '${theme.accent}$count${theme.reset}/${theme.dim}$total${theme.reset} • ${names.join('${theme.dim}, ${theme.reset}')} $more';
    }

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: label,
      theme: theme,
      bindings: bindings,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    void render(RenderOutput out) {
      // Responsive rows from terminal lines: reserve around 7 for chrome/hints
      nav.maxVisible = (TerminalInfo.rows - 7).clamp(5, maxVisible);

      frame.render(out, (ctx) {
        // Summary line
        ctx.gutterLine(summaryLine());

        // Connector after summary
        ctx.writeConnector();

        // Use ListNavigation's viewport for visible window
        final window = nav.visibleWindow(options);

        // Optional overflow indicator (top)
        if (window.hasOverflowAbove) {
          ctx.overflowIndicator();
        }

        final cols = TerminalInfo.columns;
        for (var i = 0; i < window.items.length; i++) {
          final absoluteIdx = window.start + i;
          final isFocused = nav.isSelected(absoluteIdx);
          final isChecked = selected.contains(absoluteIdx);

          // Use LineBuilder for arrow and checkbox
          final arrow = ctx.lb.arrow(isFocused);
          final check = ctx.lb.checkbox(isChecked);

          // Construct core line and fit within terminal width with graceful truncation
          var core = '$arrow $check ${window.items[i]}';
          final reserve = 0; // no trailing widget for now
          final gutterLen = ctx.lb.gutter().length;
          final maxLabel = (cols - gutterLen - 1 - reserve).clamp(8, cols);
          if (core.length > maxLabel) {
            core = '${core.substring(0, maxLabel - 3)}...';
          }

          // Use LineBuilder's writeLine for consistent highlight handling
          ctx.highlightedLine(core, highlighted: isFocused);
        }

        // Optional overflow indicator (bottom)
        if (window.hasOverflowBelow) {
          ctx.overflowIndicator();
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    if (cancelled || result == PromptResult.cancelled) return <String>[];
    if (selected.isEmpty) selected.add(nav.selectedIndex);
    final sortedIndices = selected.toList()..sort();
    return sortedIndices.map((i) => options[i]).toList(growable: false);
  }
}
