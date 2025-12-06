import '../style/theme.dart';
import '../system/ranked_list_prompt.dart';
import '../system/terminal.dart';
import '../system/text_utils.dart' as text;

/// Represents a command in the palette.
class CommandEntry {
  final String id;
  final String title;
  final String? subtitle;

  const CommandEntry({required this.id, required this.title, this.subtitle});
}

/// A VS Code–style command palette with fuzzy finding and themed UI.
///
/// Controls:
/// - Type to fuzzy search commands
/// - ↑ / ↓ to navigate
/// - Enter to confirm
/// - Backspace to erase
/// - Esc to cancel
/// - Ctrl+R to toggle fuzzy <-> substring mode
///
/// **Implementation:** Uses [RankedListPrompt] for core functionality,
/// demonstrating composition over inheritance.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final cmd = CommandPalette(commands: cmds)
///   .withMatrixTheme()
///   .run();
/// ```
class CommandPalette with Themeable {
  final List<CommandEntry> commands;
  final String label;
  @override
  final PromptTheme theme;
  final int maxVisible;

  CommandPalette({
    required this.commands,
    this.label = 'Command Palette',
    this.theme = PromptTheme.dark,
    this.maxVisible = 12,
  });

  @override
  CommandPalette copyWithTheme(PromptTheme theme) {
    return CommandPalette(
      commands: commands,
      label: label,
      theme: theme,
      maxVisible: maxVisible,
    );
  }

  /// Returns the selected command, or null if cancelled.
  CommandEntry? run() {
    if (commands.isEmpty) return null;

    final prompt = RankedListPrompt<CommandEntry>(
      title: label,
      items: commands,
      theme: theme,
      maxVisible: maxVisible,
    );

    return prompt.run(
      // Custom ranking that checks both title and subtitle
      rankItem: (entry, query, useFuzzy) {
        if (query.isEmpty) return const RankResult(0, []);

        // Try title first
        final titleMatch = useFuzzy
            ? fuzzyMatch(entry.title, query)
            : substringMatch(entry.title, query);

        if (titleMatch != null) return titleMatch;

        // Fall back to subtitle
        if (entry.subtitle != null) {
          final subMatch = useFuzzy
              ? fuzzyMatch(entry.subtitle!, query)
              : substringMatch(entry.subtitle!, query);

          if (subMatch != null) {
            // Return with reduced score and empty spans (subtitle match)
            return RankResult(subMatch.score ~/ 2, const []);
          }
        }

        return null;
      },
      itemLabel: (entry) => entry.title,
      itemSubtitle: (entry) => entry.subtitle,

      // Custom rendering with subtitle and span highlighting
      renderItem: (ctx, rankedItem, index, isFocused, query) {
        final cols = TerminalInfo.columns;
        final arrow = ctx.lb.arrow(isFocused);

        // Highlight matched spans in title
        final highlightedTitle = highlightSpans(
          rankedItem.item.title,
          rankedItem.spans,
          theme,
        );

        // Add truncated subtitle if present
        final subtitle = rankedItem.item.subtitle;
        final subtitlePart = subtitle == null
            ? ''
            : '  ${theme.dim}${text.truncate(subtitle, cols ~/ 2)}${theme.reset}';

        ctx.highlightedLine(
          '$arrow $highlightedTitle$subtitlePart',
          highlighted: isFocused,
        );
      },

      // Custom header showing mode and match count
      beforeItems: (ctx, query, useFuzzy, matchCount) {
        ctx.headerLine('Command', query);
        ctx.writeConnector();
        final mode = useFuzzy ? 'Fuzzy' : 'Substring';
        ctx.infoLine([mode, 'Matches: $matchCount']);
      },
    );
  }
}
