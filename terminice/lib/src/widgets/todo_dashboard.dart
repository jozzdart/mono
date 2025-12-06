import '../style/theme.dart';
import '../system/focus_navigation.dart';
import '../system/key_bindings.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/widget_frame.dart';
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

/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// TodoDashboard('Tasks', tasks: tasks).withPastelTheme().run();
/// ```
class TodoDashboard with Themeable {
  final String title;
  final List<TodoTask> tasks;
  final List<String> availableTags;
  @override
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

  @override
  TodoDashboard copyWithTheme(PromptTheme theme) {
    return TodoDashboard(
      title,
      tasks: tasks,
      availableTags: availableTags,
      theme: theme,
      useTerminalWidth: useTerminalWidth,
    );
  }

  /// Interactive board. Returns the final list of tasks (possibly updated).
  /// If cancelled, returns the original list unchanged.
  List<TodoTask> run() {
    if (tasks.isEmpty) return tasks;

    // Use centralized line builder for consistent styling
    final lb = LineBuilder(theme);

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

    // Use centralized checkbox from LineBuilder
    String checkbox(bool done, {bool highlight = false}) =>
        lb.checkboxHighlighted(done, highlight: highlight);

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

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () => focus.moveUp(),
          onDown: () => focus.moveDown(),
        ) +
        KeyBindings([
          // Priority with ←/→
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              adjustPriority(focus.focusedIndex, false);
              return KeyActionResult.handled;
            },
            hintLabel: '←/→ or [ / ]',
            hintDescription: 'priority',
          ),
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              adjustPriority(focus.focusedIndex, true);
              return KeyActionResult.handled;
            },
          ),
          // Priority with [ / ]
          KeyBinding.char(
            (c) => c == '[',
            (event) {
              adjustPriority(focus.focusedIndex, false);
              return KeyActionResult.handled;
            },
          ),
          KeyBinding.char(
            (c) => c == ']',
            (event) {
              adjustPriority(focus.focusedIndex, true);
              return KeyActionResult.handled;
            },
          ),
          // Toggle done
          KeyBinding.single(
            KeyEventType.space,
            (event) {
              toggleDone(focus.focusedIndex);
              return KeyActionResult.handled;
            },
            hintLabel: 'Space',
            hintDescription: 'toggle done',
          ),
          // Edit tags
          KeyBinding.char(
            (c) => c.toLowerCase() == 't',
            (event) {
              editTags(focus.focusedIndex);
              return KeyActionResult.handled;
            },
            hintLabel: 'T',
            hintDescription: 'edit tags',
          ),
        ]) +
        KeyBindings.confirm() +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final widgetFrame = WidgetFrame(
        title: title,
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.grid,
        showConnector: true,
      );

      widgetFrame.render(out, (ctx) {
        final l = layout();
        final style = theme.style;

        // Header
        final header = StringBuffer();
        header.write('${theme.dim}Task${theme.reset}'.padRight(l.titleWidth));
        header.write('  ');
        header.write('${theme.dim}Priority${theme.reset}'.padRight(l.prioWidth));
        header.write('  ');
        header.write('${theme.dim}Tags${theme.reset}'.padRight(l.tagWidth));
        ctx.gutterLine(header.toString());

        // Underline-like connector sized to content
        ctx.line(
            '${theme.gray}${style.borderConnector}${'─' * (l.content)}${theme.reset}');

        for (var i = 0; i < current.length; i++) {
          final isFocused = focus.isFocused(i);
          final t = current[i];

          final arrow = lb.arrow(isFocused);
          final cb = checkbox(t.done, highlight: isFocused);
          final titleTxt = truncate(t.title, l.titleWidth).padRight(l.titleWidth);
          final prio = priorityBadge(t.priority).padRight(l.prioWidth);
          final tags = renderTags(t.tags, l.tagWidth);

          final line = StringBuffer();
          line.write('$arrow $cb ');
          line.write(titleTxt);
          line.write('  ');
          line.write(prio);
          line.write('  ');
          line.write(tags);
          ctx.gutterLine(line.toString());
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return (cancelled || result == PromptResult.cancelled) ? initial : current;
  }
}
