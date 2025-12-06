import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
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
class CommandPalette {
  final List<CommandEntry> commands;
  final String label;
  final PromptTheme theme;
  final int maxVisible;

  CommandPalette({
    required this.commands,
    this.label = 'Command Palette',
    this.theme = PromptTheme.dark,
    this.maxVisible = 12,
  });

  /// Returns the selected command, or null if cancelled.
  CommandEntry? run() {
    if (commands.isEmpty) return null;

    final style = theme.style;

    String query = '';
    bool useFuzzy = true;
    bool cancelled = false;

    List<_RankedCommand> ranked = _rank(commands, query, useFuzzy);

    // Use centralized list navigation for selection & scrolling
    final nav = ListNavigation(
      itemCount: ranked.length,
      maxVisible: maxVisible,
    );

    void updateRanking() {
      ranked = _rank(commands, query, useFuzzy);
      nav.itemCount = ranked.length;
    }

    void render(RenderOutput out) {
      // Responsive rows based on current terminal size
      final cols = TerminalInfo.columns;
      final lines = TerminalInfo.rows;
      // Reserve: 1 title + 1 query + 1 connector + 1 mode line + 1 bottom + 4 hints ≈ 8
      nav.maxVisible = (lines - 8).clamp(5, maxVisible);

      final frame = FramedLayout(label, theme: theme);
      final title = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$title${theme.reset}' : title);

      // Query line
      final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      out.writeln(
          '$framePrefix${theme.accent}Command:${theme.reset} $query');

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Mode and counts line
      final mode = useFuzzy ? 'Fuzzy' : 'Substring';
      final countText = 'Matches: ${ranked.length}';
      final infoLine = '$mode   $countText';
      out.writeln('$framePrefix${theme.dim}$infoLine${theme.reset}');

      // Use ListNavigation's viewport for visible window
      final window = nav.visibleWindow(ranked);

      if (window.hasOverflowAbove) {
        out.writeln('$framePrefix${theme.dim}...${theme.reset}');
      }

      for (var i = 0; i < window.items.length; i++) {
        final absoluteIdx = window.start + i;
        final isHighlighted = nav.isSelected(absoluteIdx);
        final prefixSel =
            isHighlighted ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';

        // Compose display text with highlighted match spans
        final rankedItem = window.items[i];
        final highlightedTitle = _highlightSpans(
          rankedItem.entry.title,
          rankedItem.titleSpans,
          theme,
        );
        final subtitle = rankedItem.entry.subtitle;
        final subtitlePart = subtitle == null
            ? ''
            : '  ${theme.dim}${text.truncate(subtitle, cols ~/ 2)}${theme.reset}';

        final lineCore = '$prefixSel $highlightedTitle$subtitlePart';

        if (isHighlighted && style.useInverseHighlight) {
          out.writeln('$framePrefix${theme.inverse}$lineCore${theme.reset}');
        } else {
          out.writeln('$framePrefix$lineCore');
        }
      }

      if (window.hasOverflowBelow) {
        out.writeln('$framePrefix${theme.dim}...${theme.reset}');
      }

      if (ranked.isEmpty) {
        out.writeln(
            '$framePrefix${theme.dim}(no matches)${theme.reset}');
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.grid([
        [Hints.key('type', theme), 'search commands'],
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Enter', theme), 'run'],
        [Hints.key('Backspace', theme), 'erase'],
        [Hints.key('Ctrl+R', theme), 'toggle mode'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    // Initial
    updateRanking();

    CommandEntry? result;

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.arrowUp) {
          nav.moveUp();
        } else if (ev.type == KeyEventType.arrowDown) {
          nav.moveDown();
        } else if (ev.type == KeyEventType.enter) {
          if (ranked.isNotEmpty) {
            result = ranked[nav.selectedIndex].entry;
          }
          return PromptResult.confirmed;
        } else if (ev.type == KeyEventType.esc) {
          cancelled = true;
          return PromptResult.cancelled;
        } else if (ev.type == KeyEventType.backspace) {
          if (query.isNotEmpty) {
            query = query.substring(0, query.length - 1);
            updateRanking();
          }
        } else if (ev.type == KeyEventType.ctrlR) {
          useFuzzy = !useFuzzy;
          updateRanking();
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          query += ev.char!;
          updateRanking();
        }

        return null;
      },
    );

    return cancelled ? null : result;
  }
}

class _RankedCommand {
  final CommandEntry entry;
  final int score;
  final List<int> titleSpans;

  _RankedCommand(this.entry, this.score, this.titleSpans);
}

List<_RankedCommand> _rank(List<CommandEntry> entries, String query, bool fuzzy) {
  if (query.isEmpty) {
    return entries
        .map((e) => _RankedCommand(e, 0, const []))
        .toList(growable: false);
  }

  final results = <_RankedCommand>[];
  for (final e in entries) {
    _FuzzyMatchResult? r;
    if (fuzzy) {
      r = _fuzzyMatch(e.title, query);
      // Consider subtitle as secondary boost for visibility in fuzzy mode
      if (r == null && e.subtitle != null) {
        final sub = _fuzzyMatch(e.subtitle!, query);
        if (sub != null) {
          // show title spans unchanged but give a small bonus score so it appears
          r = _FuzzyMatchResult(sub.score ~/ 2, const []);
        }
      }
    } else {
      final idx = e.title.toLowerCase().indexOf(query.toLowerCase());
      if (idx != -1) {
        r = _FuzzyMatchResult(100000 - idx * 100,
            List<int>.generate(query.length, (i) => idx + i));
      } else if (e.subtitle != null) {
        final sidx = e.subtitle!.toLowerCase().indexOf(query.toLowerCase());
        if (sidx != -1) {
          r = _FuzzyMatchResult(50000 - sidx * 50, const []);
        }
      }
    }

    if (r != null) {
      results.add(_RankedCommand(e, r.score, r.indices));
    }
  }

  results.sort((a, b) {
    final sc = b.score.compareTo(a.score);
    if (sc != 0) return sc;
    return a.entry.title.toLowerCase().compareTo(b.entry.title.toLowerCase());
  });
  return results;
}

class _FuzzyMatchResult {
  final int score;
  final List<int> indices;
  _FuzzyMatchResult(this.score, this.indices);
}

// Simple, effective fuzzy matcher: sequential char matching with bonuses.
_FuzzyMatchResult? _fuzzyMatch(String text, String pattern) {
  final t = text.toLowerCase();
  final p = pattern.toLowerCase();
  int ti = 0;
  final matched = <int>[];

  for (var pi = 0; pi < p.length; pi++) {
    final ch = p[pi];
    final found = t.indexOf(ch, ti);
    if (found == -1) return null;
    matched.add(found);
    ti = found + 1;
  }

  // Scoring: prefer contiguous, early, word-boundary and case-exact matches
  int score = 0;
  if (matched.isEmpty) return null;
  // Base: more compact span is better
  final span = matched.last - matched.first + 1;
  score += max(0, 100000 - span * 300);
  // Contiguity bonus
  for (var i = 1; i < matched.length; i++) {
    if (matched[i] == matched[i - 1] + 1) score += 1200;
  }
  // Early start bonus
  score += max(0, 8000 - matched.first * 200);
  // Word boundary bonus (space or - or _ before)
  final before = matched.first > 0 ? text[matched.first - 1] : ' ';
  if (before == ' ' || before == '-' || before == '_' || before == '/' || before == '.') {
    score += 2500;
  }
  // Exact case bonus
  for (final i in matched) {
    if (text[i] == pattern[matched.indexOf(i)]) score += 150;
  }

  return _FuzzyMatchResult(score, matched);
}

String _highlightSpans(String text, List<int> indices, PromptTheme theme) {
  if (indices.isEmpty) return text;
  final set = indices.toSet();
  final buf = StringBuffer();
  bool inSpan = false;
  for (var i = 0; i < text.length; i++) {
    final isMatch = set.contains(i);
    if (isMatch && !inSpan) {
      buf.write(theme.highlight);
      inSpan = true;
    } else if (!isMatch && inSpan) {
      buf.write(theme.reset);
      inSpan = false;
    }
    buf.write(text[i]);
  }
  if (inSpan) buf.write(theme.reset);
  return buf.toString();
}

// Uses text.truncate from text_utils.dart
