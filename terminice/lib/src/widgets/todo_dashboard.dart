import '../style/theme.dart';
import '../system/focus_navigation.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import 'tag_selector.dart';

/// TodoDashboard – full task board (with tags and priorities)
///
/// Controls:
/// - ↑ / ↓ navigate between tasks
/// - Space toggles completion
/// - ← / → adjusts priority (or [ / ] as alternatives)
/// - T edits tags via TagSelector
/// - Enter confirms
/// - Esc / Ctrl+C cancels (reverts to initial state)
class TodoTask {
  final String title;
  final List<String> tags;
  final TodoPriority priority;
  final bool done;

  const TodoTask(this.title,
      {this.tags = const [],
      this.priority = TodoPriority.medium,
      this.done = false});

  TodoTask copyWith({
    String? title,
    List<String>? tags,
    TodoPriority? priority,
    bool? done,
  }) {
    return TodoTask(title ?? this.title,
        tags: tags ?? this.tags,
        priority: priority ?? this.priority,
        done: done ?? this.done);
  }
}

enum TodoPriority { low, medium, high }

class TodoDashboard {
  final String title;
  final List<TodoTask> tasks;
  final List<String> availableTags;
  final PromptTheme theme;

  /// If true, content width will attempt to align to terminal width; otherwise uses a relaxed fixed width.
  final bool useTerminalWidth;

  TodoDashboard(
    this.title, {
    required this.tasks,
    this.availableTags = const [],
    this.theme = PromptTheme.dark,
    this.useTerminalWidth = true,
  });

  /// Interactive board. Returns the final list of tasks (possibly updated).
  /// If cancelled, returns the original list unchanged.
  List<TodoTask> run() {
    if (tasks.isEmpty) return tasks;

    final style = theme.style;

    // Use centralized focus navigation
    final focus = FocusNavigation(itemCount: tasks.length);
    bool cancelled = false;
    var current = List<TodoTask>.from(tasks);
    final initial = List<TodoTask>.from(tasks);

    ({int content, int titleWidth, int tagWidth, int prioWidth}) layout() {
      final termCols = useTerminalWidth ? TerminalInfo.columns : 80;
      final content = (termCols - 4).clamp(48, 200);

      // Columns: [arrow][checkbox] [title] [priority] [tags]
      const prioWidth = 9; // e.g. [HIGH]
      final tagWidth = (content / 3).round().clamp(14, 48);
      final titleWidth =
          (content - 6 /*arrow+cb+spaces*/ - prioWidth - tagWidth)
              .clamp(10, content);
      return (
        content: content,
        titleWidth: titleWidth,
        tagWidth: tagWidth,
        prioWidth: prioWidth
      );
    }

    String checkbox(bool done, {bool highlight = false}) {
      final sym = done ? style.checkboxOnSymbol : style.checkboxOffSymbol;
      final color = done ? theme.checkboxOn : theme.checkboxOff;
      final out = '$color$sym${theme.reset}';
      if (highlight && style.useInverseHighlight) {
        return '${theme.inverse}$out${theme.reset}';
      }
      return out;
    }

    String priorityBadge(TodoPriority p) {
      switch (p) {
        case TodoPriority.high:
          return '${theme.error}[HIGH]${theme.reset}';
        case TodoPriority.medium:
          return '${theme.highlight}[MED]${theme.reset}';
        case TodoPriority.low:
          return '${theme.info}[LOW]${theme.reset}';
      }
    }

    TodoPriority raise(TodoPriority p) {
      switch (p) {
        case TodoPriority.low:
          return TodoPriority.medium;
        case TodoPriority.medium:
          return TodoPriority.high;
        case TodoPriority.high:
          return TodoPriority.high;
      }
    }

    TodoPriority lower(TodoPriority p) {
      switch (p) {
        case TodoPriority.high:
          return TodoPriority.medium;
        case TodoPriority.medium:
          return TodoPriority.low;
        case TodoPriority.low:
          return TodoPriority.low;
      }
    }

    String truncate(String text, int max) {
      if (text.length <= max) return text;
      if (max <= 1) return text.substring(0, max);
      return '${text.substring(0, max - 1)}…';
    }

    String renderTags(List<String> tags, int tagWidth) {
      if (tags.isEmpty) {
        return '${theme.dim}(no tags)${theme.reset}'.padRight(tagWidth);
      }
      final chips = tags.map((t) => '[$t]').join(' ');
      final truncated = truncate(chips, tagWidth);
      // lightly accent the brackets but keep content bright
      return truncated
          .replaceAll('[', '${theme.dim}[')
          .replaceAll(']', ']${theme.reset}')
          .padRight(tagWidth);
    }

    void render(RenderOutput out) {
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      final leftPrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      final l = layout();

      // Header
      final header = StringBuffer();
      header.write(leftPrefix);
      header.write('${theme.dim}Task${theme.reset}'.padRight(l.titleWidth));
      header.write('  ');
      header.write('${theme.dim}Priority${theme.reset}'.padRight(l.prioWidth));
      header.write('  ');
      header.write('${theme.dim}Tags${theme.reset}'.padRight(l.tagWidth));
      out.writeln(header.toString());

      // Underline-like connector sized to content
      out.writeln(
          '${theme.gray}${style.borderConnector}${'─' * (l.content)}${theme.reset}');

      for (var i = 0; i < current.length; i++) {
        final isFocused = focus.isFocused(i);
        final t = current[i];

        final arrow =
            isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final cb = checkbox(t.done, highlight: isFocused);
        final titleTxt = truncate(t.title, l.titleWidth).padRight(l.titleWidth);
        final prio = priorityBadge(t.priority).padRight(l.prioWidth);
        final tags = renderTags(t.tags, l.tagWidth);

        final line = StringBuffer();
        line.write(leftPrefix);
        line.write('$arrow $cb ');
        line.write(titleTxt);
        line.write('  ');
        line.write(prio);
        line.write('  ');
        line.write(tags);
        out.writeln(line.toString());
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Space', theme), 'toggle done'],
        [Hints.key('←/→ or [ / ]', theme), 'priority'],
        [Hints.key('T', theme), 'edit tags'],
        [Hints.key('Enter', theme), 'confirm'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    void toggleDone(int i) {
      final t = current[i];
      current[i] = t.copyWith(done: !t.done);
    }

    void adjustPriority(int i, bool raisePriority) {
      final t = current[i];
      current[i] = t.copyWith(
          priority: raisePriority ? raise(t.priority) : lower(t.priority));
    }

    void editTags(int i) {
      if (availableTags.isEmpty) return;

      // Best-effort: use TagSelector (doesn't support initial preselect here)
      final selector =
          TagSelector(availableTags, prompt: 'Select tags', theme: theme);
      final selected = selector.run();
      current[i] = current[i].copyWith(tags: selected);
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.enter) return PromptResult.confirmed;
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.arrowUp) {
          focus.moveUp();
        } else if (ev.type == KeyEventType.arrowDown) {
          focus.moveDown();
        } else if (ev.type == KeyEventType.arrowLeft) {
          adjustPriority(focus.focusedIndex, false);
        } else if (ev.type == KeyEventType.arrowRight) {
          adjustPriority(focus.focusedIndex, true);
        } else if (ev.type == KeyEventType.space) {
          toggleDone(focus.focusedIndex);
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          if (ch == ']') adjustPriority(focus.focusedIndex, true);
          if (ch == '[') adjustPriority(focus.focusedIndex, false);
          if (ch.toLowerCase() == 't') editTags(focus.focusedIndex);
        }

        return null;
      },
    );

    return (cancelled || result == PromptResult.cancelled) ? initial : current;
  }
}
