import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
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
      {this.tags = const [], this.priority = TodoPriority.medium, this.done = false});

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

    int focused = 0;
    bool cancelled = false;
    var current = List<TodoTask>.from(tasks);
    final initial = List<TodoTask>.from(tasks);

    int _terminalColumns() {
      try {
        if (stdout.hasTerminal) return stdout.terminalColumns;
      } catch (_) {}
      return 80;
    }

    ({int content, int titleWidth, int tagWidth, int prioWidth}) layout() {
      final termCols = useTerminalWidth ? _terminalColumns() : 80;
      final content = (termCols - 4).clamp(48, 200);

      // Columns: [arrow][checkbox] [title] [priority] [tags]
      const prioWidth = 9; // e.g. [HIGH]
      final tagWidth = (content / 3).round().clamp(14, 48);
      final titleWidth = (content - 6 /*arrow+cb+spaces*/ - prioWidth - tagWidth)
          .clamp(10, content);
      return (content: content, titleWidth: titleWidth, tagWidth: tagWidth, prioWidth: prioWidth);
    }

    String _checkbox(bool done, {bool highlight = false}) {
      final sym = done ? style.checkboxOnSymbol : style.checkboxOffSymbol;
      final color = done ? theme.checkboxOn : theme.checkboxOff;
      final out = '$color$sym${theme.reset}';
      if (highlight && style.useInverseHighlight) return '${theme.inverse}$out${theme.reset}';
      return out;
    }

    String _priorityBadge(TodoPriority p) {
      switch (p) {
        case TodoPriority.high:
          return '${theme.error}[HIGH]${theme.reset}';
        case TodoPriority.medium:
          return '${theme.highlight}[MED]${theme.reset}';
        case TodoPriority.low:
          return '${theme.info}[LOW]${theme.reset}';
      }
    }

    TodoPriority _raise(TodoPriority p) {
      switch (p) {
        case TodoPriority.low:
          return TodoPriority.medium;
        case TodoPriority.medium:
          return TodoPriority.high;
        case TodoPriority.high:
          return TodoPriority.high;
      }
    }

    TodoPriority _lower(TodoPriority p) {
      switch (p) {
        case TodoPriority.high:
          return TodoPriority.medium;
        case TodoPriority.medium:
          return TodoPriority.low;
        case TodoPriority.low:
          return TodoPriority.low;
      }
    }

    String _truncate(String text, int max) {
      if (text.length <= max) return text;
      if (max <= 1) return text.substring(0, max);
      return text.substring(0, max - 1) + '…';
    }

    String _renderTags(List<String> tags, int tagWidth) {
      if (tags.isEmpty) return '${theme.dim}(no tags)${theme.reset}'.padRight(tagWidth);
      final chips = tags.map((t) => '[${t}]').join(' ');
      final truncated = _truncate(chips, tagWidth);
      // lightly accent the brackets but keep content bright
      return truncated
          .replaceAll('[', '${theme.dim}[')
          .replaceAll(']', ']${theme.reset}')
          .padRight(tagWidth);
    }

    void render() {
      Terminal.clearAndHome();

      final top = style.showBorder
          ? FrameRenderer.titleWithBorders(title, theme)
          : FrameRenderer.plainTitle(title, theme);
      stdout.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(title, theme));
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
      stdout.writeln(header.toString());

      // Underline-like connector sized to content
      stdout.writeln(
          '${theme.gray}${style.borderConnector}${'─' * (l.content)}${theme.reset}');

      for (var i = 0; i < current.length; i++) {
        final isFocused = i == focused;
        final t = current[i];

        final arrow = isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final cb = _checkbox(t.done, highlight: isFocused);
        final titleTxt = _truncate(t.title, l.titleWidth).padRight(l.titleWidth);
        final prio = _priorityBadge(t.priority).padRight(l.prioWidth);
        final tags = _renderTags(t.tags, l.tagWidth);

        final line = StringBuffer();
        line.write(leftPrefix);
        line.write('$arrow $cb ');
        line.write(titleTxt);
        line.write('  ');
        line.write(prio);
        line.write('  ');
        line.write(tags);
        stdout.writeln(line.toString());
      }

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(title, theme));
      }

      stdout.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Space', theme), 'toggle done'],
        [Hints.key('←/→ or [ / ]', theme), 'priority'],
        [Hints.key('T', theme), 'edit tags'],
        [Hints.key('Enter', theme), 'confirm'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));

      Terminal.hideCursor();
    }

    int _moveUp(int i) => (i - 1 + current.length) % current.length;
    int _moveDown(int i) => (i + 1) % current.length;

    void _toggleDone(int i) {
      final t = current[i];
      current[i] = t.copyWith(done: !t.done);
    }

    void _adjustPriority(int i, bool raise) {
      final t = current[i];
      current[i] = t.copyWith(priority: raise ? _raise(t.priority) : _lower(t.priority));
    }

    void _editTags(int i) {
      if (availableTags.isEmpty) return;

      // Best-effort: use TagSelector (doesn't support initial preselect here)
      final selector = TagSelector(availableTags, prompt: 'Select tags', theme: theme);
      final selected = selector.run();
      current[i] = current[i].copyWith(tags: selected);
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
          focused = _moveUp(focused);
        } else if (ev.type == KeyEventType.arrowDown) {
          focused = _moveDown(focused);
        } else if (ev.type == KeyEventType.arrowLeft) {
          _adjustPriority(focused, false);
        } else if (ev.type == KeyEventType.arrowRight) {
          _adjustPriority(focused, true);
        } else if (ev.type == KeyEventType.space) {
          _toggleDone(focused);
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          if (ch == ']') _adjustPriority(focused, true);
          if (ch == '[') _adjustPriority(focused, false);
          if (ch.toLowerCase() == 't') _editTags(focused);
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    return cancelled ? initial : current;
  }
}


