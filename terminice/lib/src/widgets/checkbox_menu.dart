import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/selectable_list_prompt.dart';
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
///
/// **Implementation:** Uses [SelectableListPrompt] for core functionality,
/// demonstrating composition over inheritance.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final selected = CheckboxMenu(label: 'Options', options: items)
///   .withMatrixTheme()
///   .run();
/// ```
class CheckboxMenu with Themeable {
  final String label;
  final List<String> options;
  @override
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

  @override
  CheckboxMenu copyWithTheme(PromptTheme theme) {
    return CheckboxMenu(
      label: label,
      options: options,
      theme: theme,
      maxVisible: maxVisible,
      initialSelected: initialSelected,
    );
  }

  List<String> run() {
    if (options.isEmpty) return <String>[];

    // Use SelectableListPrompt for centralized state management
    final prompt = SelectableListPrompt<String>(
      title: label,
      items: options,
      theme: theme,
      multiSelect: true,
      maxVisible: maxVisible,
      initialSelection: initialSelected,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    // Summary line builder (captures prompt for access to selection state)
    String buildSummaryLine() {
      final total = options.length;
      final count = prompt.selection.count;
      if (count == 0) {
        return '${theme.dim}(none selected)${theme.reset}';
      }
      // render up to 3 selections by label, then "+N"
      final indices = prompt.selection.getSelectedIndices();
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

    return prompt.runCustom(
      // Add select-all binding ('A' key)
      extraBindings: KeyBindings.letter(
        char: 'A',
        onPress: () => prompt.selection.toggleAll(options.length),
        hintDescription: 'select all / clear',
      ),

      // Summary line before items
      beforeItems: (ctx) {
        ctx.gutterLine(buildSummaryLine());
        ctx.writeConnector();
      },

      // Render each item with checkbox
      renderItem: (ctx, item, absoluteIdx, isFocused, isChecked) {
        final arrow = ctx.lb.arrow(isFocused);
        final check = ctx.lb.checkbox(isChecked);

        // Construct core line and fit within terminal width with graceful truncation
        final cols = TerminalInfo.columns;
        var core = '$arrow $check $item';
        final reserve = 0; // no trailing widget for now
        final gutterLen = ctx.lb.gutter().length;
        final maxLabel = (cols - gutterLen - 1 - reserve).clamp(8, cols);
        if (core.length > maxLabel) {
          core = '${core.substring(0, maxLabel - 3)}...';
        }

        ctx.highlightedLine(core, highlighted: isFocused);
      },
    );
  }
}
