import 'dart:async';
import 'dart:io' show sleep, stdout;

import '../style/theme.dart';
import 'framed_layout.dart';
import 'hints.dart';
import 'key_bindings.dart';
import 'line_builder.dart';
import 'list_navigation.dart';
import 'prompt_runner.dart';

/// WidgetFrame – Composable frame rendering for terminal widgets.
///
/// Eliminates the common boilerplate pattern found across widgets:
/// - Create FramedLayout
/// - Write top (with conditional bold)
/// - Write content lines with LineBuilder
/// - Write bottom border (conditionally)
/// - Write hints from KeyBindings
///
/// **Before WidgetFrame:**
/// ```dart
/// void render(RenderOutput out) {
///   final style = theme.style;
///   final lb = LineBuilder(theme);
///   final frame = FramedLayout(title, theme: theme);
///
///   out.writeln(style.boldPrompt
///     ? '${theme.bold}${frame.top()}${theme.reset}'
///     : frame.top());
///
///   // ... 10+ lines of content setup ...
///
///   if (style.showBorder) {
///     out.writeln(frame.bottom());
///   }
///
///   out.writeln(bindings.toHintsBullets(theme));
/// }
/// ```
///
/// **After WidgetFrame:**
/// ```dart
/// void render(RenderOutput out) {
///   final wf = WidgetFrame(title: title, theme: theme, bindings: bindings);
///   wf.render(out, (ctx) {
///     ctx.line('Content line');
///     ctx.gutterLine('Indented content');
///   });
/// }
/// ```
///
/// **Features:**
/// - Automatic themed frame (top/bottom borders)
/// - `FrameContext` provides `LineBuilder` + convenience methods
/// - Automatic hints from KeyBindings
/// - Connector line support
/// - Consistent styling across all widgets
///
/// **Design principles:**
/// - Composition over inheritance
/// - Separation of concerns (frame rendering vs widget logic)
/// - Backward compatible (use alongside existing patterns)
class WidgetFrame {
  /// Title displayed in the frame header.
  final String title;

  /// Theme for colors and styling.
  final PromptTheme theme;

  /// Key bindings for hint generation.
  final KeyBindings? bindings;

  /// Hint display style.
  final HintStyle hintStyle;

  /// Whether to show a connector line after the header.
  final bool showConnector;

  const WidgetFrame({
    required this.title,
    required this.theme,
    this.bindings,
    this.hintStyle = HintStyle.bullets,
    this.showConnector = false,
  });

  /// Shorthand access to the style.
  PromptStyle get style => theme.style;

  /// Renders the complete widget frame with content.
  ///
  /// [content] receives a [FrameContext] with helper methods for writing
  /// styled lines. The frame handles top, bottom, and hints automatically.
  ///
  /// Example:
  /// ```dart
  /// wf.render(out, (ctx) {
  ///   ctx.gutterLine('${theme.accent}Name:${theme.reset} $name');
  ///   ctx.gutterLine('${ctx.lb.checkbox(selected)} Toggle option');
  /// });
  /// ```
  void render(
    RenderOutput out,
    void Function(FrameContext ctx) content,
  ) {
    final frame = FramedLayout(title, theme: theme);
    final lb = LineBuilder(theme);
    final ctx = FrameContext._(out, lb, theme, frame);

    // Top border
    ctx.writeTop();

    // Optional connector
    if (showConnector && style.showBorder) {
      out.writeln(frame.connector());
    }

    // Content callback
    content(ctx);

    // Bottom border
    if (style.showBorder) {
      out.writeln(frame.bottom());
    }

    // Hints
    if (bindings != null) {
      _writeHints(out, bindings!);
    }
  }

  /// Renders without hints (for nested/partial renders).
  void renderContent(
    RenderOutput out,
    void Function(FrameContext ctx) content,
  ) {
    final frame = FramedLayout(title, theme: theme);
    final lb = LineBuilder(theme);
    final ctx = FrameContext._(out, lb, theme, frame);

    ctx.writeTop();

    if (showConnector && style.showBorder) {
      out.writeln(frame.connector());
    }

    content(ctx);

    if (style.showBorder) {
      out.writeln(frame.bottom());
    }
  }

  /// Writes hints in the configured style.
  void _writeHints(RenderOutput out, KeyBindings bindings) {
    switch (hintStyle) {
      case HintStyle.bullets:
        out.writeln(bindings.toHintsBullets(theme));
        break;
      case HintStyle.grid:
        out.writeln(bindings.toHintsGrid(theme));
        break;
      case HintStyle.inline:
        final entries = bindings.toHintEntries();
        final hints = entries.map((e) => '${e[0]}: ${e[1]}').toList();
        out.writeln(Hints.comma(hints, theme));
        break;
      case HintStyle.none:
        break;
    }
  }
}

/// Hint display style options.
enum HintStyle {
  /// Bullet-style hints (default).
  bullets,

  /// Grid-style hints.
  grid,

  /// Inline comma-separated hints.
  inline,

  /// No hints displayed.
  none,
}

/// Context passed to the content callback during frame rendering.
///
/// Provides convenient methods for writing styled content lines
/// within the frame. Wraps `LineBuilder` and `RenderOutput` together.
class FrameContext {
  /// The render output to write to.
  final RenderOutput out;

  /// LineBuilder for consistent styling.
  final LineBuilder lb;

  /// Theme for colors and ANSI codes.
  final PromptTheme theme;

  /// Frame layout for structure.
  final FramedLayout frame;

  const FrameContext._(this.out, this.lb, this.theme, this.frame);

  /// Shorthand access to the style.
  PromptStyle get style => theme.style;

  // ──────────────────────────────────────────────────────────────────────────
  // FRAME STRUCTURE
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes the top border line with optional bold styling.
  void writeTop() {
    final top = frame.top();
    out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);
  }

  /// Writes a connector line (├─────).
  void writeConnector() {
    if (style.showBorder) {
      out.writeln(frame.connector());
    }
  }

  /// Writes the bottom border line.
  void writeBottom() {
    if (style.showBorder) {
      out.writeln(frame.bottom());
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LINE WRITING
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a plain line (no gutter).
  void line(String content) {
    out.writeln(content);
  }

  /// Writes an empty line.
  void emptyLine() {
    out.writeln('');
  }

  /// Writes a line with the gutter prefix (│ content).
  void gutterLine(String content) {
    out.writeln('${lb.gutter()}$content');
  }

  /// Writes an empty gutter line (│).
  void gutterEmpty() {
    out.writeln(lb.gutterOnly());
  }

  /// Writes a line with optional inverse highlight.
  ///
  /// Delegates to LineBuilder's writeLine for consistent highlight handling.
  void highlightedLine(
    String content, {
    bool highlighted = false,
    bool includeGutter = true,
  }) {
    lb.writeLine(out, content,
        highlighted: highlighted, includeGutter: includeGutter);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STYLED CONTENT
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a selectable item line with arrow indicator.
  void selectableItem(String content, {required bool focused}) {
    lb.writeSelectableLine(out, content, focused: focused);
  }

  /// Writes a checkbox item line with arrow and checkbox.
  void checkboxItem(
    String content, {
    required bool focused,
    required bool checked,
  }) {
    lb.writeCheckboxLine(out, content, focused: focused, checked: checked);
  }

  /// Writes an overflow indicator line (│ ...).
  void overflowIndicator() {
    out.writeln(lb.overflowLine());
  }

  /// Writes an empty message line (│ (message)).
  void emptyMessage(String message) {
    out.writeln(lb.emptyLine(message));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LABELED VALUES
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a labeled value line: │ Label: Value
  void labeledValue(String label, String value, {bool dimLabel = true}) {
    final labelPart =
        dimLabel ? '${theme.dim}$label:${theme.reset}' : '$label:';
    gutterLine('$labelPart $value');
  }

  /// Writes a labeled value with accent color on the value.
  void labeledAccent(String label, String value) {
    gutterLine(
        '${theme.dim}$label:${theme.reset} ${theme.accent}$value${theme.reset}');
  }

  /// Writes a bold message line.
  void boldMessage(String message) {
    gutterLine('${theme.bold}$message${theme.reset}');
  }

  /// Writes a dimmed/muted message line.
  void dimMessage(String message) {
    gutterLine('${theme.dim}$message${theme.reset}');
  }

  /// Writes an error message line.
  void errorMessage(String message) {
    gutterLine('${theme.error}$message${theme.reset}');
  }

  /// Writes a warning message line.
  void warnMessage(String message) {
    gutterLine('${theme.warn}$message${theme.reset}');
  }

  /// Writes an info message line.
  void infoMessage(String message) {
    gutterLine('${theme.info}$message${theme.reset}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COMPOSITE PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a list of items with selection indicator.
  ///
  /// [items] is the list of items to display.
  /// [selectedIndex] is the currently selected index.
  /// [startIndex] is the offset for viewport scrolling (default 0).
  /// [itemBuilder] converts an item to its display string.
  void selectionList<T>(
    List<T> items, {
    required int selectedIndex,
    int startIndex = 0,
    String Function(T item)? itemBuilder,
  }) {
    for (var i = 0; i < items.length; i++) {
      final absoluteIndex = startIndex + i;
      final isSelected = absoluteIndex == selectedIndex;
      final text = itemBuilder?.call(items[i]) ?? items[i].toString();
      selectableItem(text, focused: isSelected);
    }
  }

  /// Writes a list of checkbox items.
  ///
  /// [items] is the list of items to display.
  /// [focusedIndex] is the currently focused index.
  /// [checkedIndices] is the set of checked item indices.
  /// [startIndex] is the offset for viewport scrolling (default 0).
  /// [itemBuilder] converts an item to its display string.
  void checkboxList<T>(
    List<T> items, {
    required int focusedIndex,
    required Set<int> checkedIndices,
    int startIndex = 0,
    String Function(T item)? itemBuilder,
  }) {
    for (var i = 0; i < items.length; i++) {
      final absoluteIndex = startIndex + i;
      final isFocused = absoluteIndex == focusedIndex;
      final isChecked = checkedIndices.contains(absoluteIndex);
      final text = itemBuilder?.call(items[i]) ?? items[i].toString();
      checkboxItem(text, focused: isFocused, checked: isChecked);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SEARCH & INPUT PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a search input line: │ Search: [query]
  void searchLine(String query, {bool enabled = true}) {
    if (enabled) {
      gutterLine('${theme.accent}Search:${theme.reset} $query');
    } else {
      dimMessage('(Search disabled — press / to enable)');
    }
  }

  /// Writes a key-value header line: │ Key: Value (key is accent, value is normal)
  void headerLine(String key, String value) {
    gutterLine('${theme.accent}$key:${theme.reset} $value');
  }

  /// Writes an input line with cursor: │ ▶ [text][cursor]
  void inputLine(String text, {bool showCursor = true, String? placeholder}) {
    final display = text.isEmpty && placeholder != null
        ? '${theme.dim}$placeholder${theme.reset}'
        : text;
    final cursor = showCursor ? '${theme.accent}▌${theme.reset}' : '';
    gutterLine('${lb.arrowAccent()} $display$cursor');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // LIST NAVIGATION INTEGRATION
  // ──────────────────────────────────────────────────────────────────────────

  /// Renders a ListWindow with selection and custom rendering.
  ///
  /// This handles overflow indicators automatically and delegates
  /// item rendering to the provided callback.
  ///
  /// Example:
  /// ```dart
  /// final window = nav.visibleWindow(items);
  /// ctx.listWindow(
  ///   window,
  ///   selectedIndex: nav.selectedIndex,
  ///   renderItem: (item, index, isFocused) {
  ///     ctx.selectableItem(item.toString(), focused: isFocused);
  ///   },
  /// );
  /// ```
  void listWindow<T>(
    ListWindow<T> window, {
    required int selectedIndex,
    required void Function(T item, int absoluteIndex, bool isFocused)
        renderItem,
  }) {
    if (window.hasOverflowAbove) {
      overflowIndicator();
    }

    for (var i = 0; i < window.items.length; i++) {
      final absoluteIndex = window.start + i;
      final isFocused = absoluteIndex == selectedIndex;
      renderItem(window.items[i], absoluteIndex, isFocused);
    }

    if (window.hasOverflowBelow) {
      overflowIndicator();
    }
  }

  /// Renders a simple selection list from a ListWindow.
  ///
  /// Convenience wrapper around [listWindow] for the common case
  /// of rendering a simple selectable list.
  void selectionWindow<T>(
    ListWindow<T> window, {
    required int selectedIndex,
    String Function(T item)? itemBuilder,
  }) {
    listWindow(
      window,
      selectedIndex: selectedIndex,
      renderItem: (item, index, isFocused) {
        final text = itemBuilder?.call(item) ?? item.toString();
        selectableItem(text, focused: isFocused);
      },
    );
  }

  /// Renders a checkbox list from a ListWindow.
  ///
  /// Convenience wrapper around [listWindow] for multi-select lists.
  void checkboxWindow<T>(
    ListWindow<T> window, {
    required int focusedIndex,
    required Set<int> checkedIndices,
    String Function(T item)? itemBuilder,
  }) {
    listWindow(
      window,
      selectedIndex: focusedIndex,
      renderItem: (item, index, isFocused) {
        final isChecked = checkedIndices.contains(index);
        final text = itemBuilder?.call(item) ?? item.toString();
        checkboxItem(text, focused: isFocused, checked: isChecked);
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CUSTOM ITEM PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a custom selectable item with a prefix before the content.
  ///
  /// Useful for items that need extra decoration beyond the arrow indicator.
  /// The prefix appears after the arrow, before the content.
  ///
  /// Example: `▶ [x] Option 1` where `[x]` is the prefix.
  void selectableItemWithPrefix(
    String content, {
    required bool focused,
    required String prefix,
  }) {
    final arrow = lb.arrow(focused);
    final line = '$arrow $prefix $content';
    highlightedLine(line, highlighted: focused);
  }

  /// Writes an item line with custom leading glyph.
  ///
  /// Useful for tree structures, icons, or other custom prefixes.
  void customItem(
    String content, {
    required bool focused,
    String? leadingGlyph,
    bool highlighted = false,
  }) {
    final arrow = lb.arrow(focused);
    final glyph = leadingGlyph != null ? '$leadingGlyph ' : '';
    final line = '$arrow $glyph$content';
    highlightedLine(line, highlighted: highlighted && focused);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MODE & INFO LINES
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a mode/info status line with multiple segments.
  ///
  /// Each segment is separated by spaces. Useful for showing
  /// multiple status indicators like "Fuzzy   Matches: 5".
  void infoLine(List<String> segments, {int spacing = 3}) {
    final separator = ' ' * spacing;
    gutterLine('${theme.dim}${segments.join(separator)}${theme.reset}');
  }

  /// Writes a summary/count line: │ count/total • item1, item2, ...
  void summaryLine(int count, int total, {List<String>? highlights}) {
    final countPart =
        '${theme.accent}$count${theme.reset}/${theme.dim}$total${theme.reset}';
    if (highlights != null && highlights.isNotEmpty) {
      final items =
          highlights.map((h) => '${theme.accent}$h${theme.reset}').join(', ');
      gutterLine('$countPart • $items');
    } else {
      gutterLine(countPart);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DISPLAY-ONLY PATTERNS
  // ──────────────────────────────────────────────────────────────────────────

  /// Writes a stat item line with icon: │ ✔ Label: Value
  ///
  /// Useful for stat cards and dashboard displays.
  void statItem(
    String label,
    String value, {
    String icon = '•',
    StatTone tone = StatTone.accent,
  }) {
    final toneColor = _toneColor(tone, theme);
    final line = StringBuffer();
    line.write('$toneColor$icon${theme.reset} ');
    line.write('${theme.dim}$label:${theme.reset} ');
    line.write('${theme.selection}${theme.bold}$value${theme.reset}');
    gutterLine(line.toString());
  }

  /// Writes a styled message line with icon: │ ℹ Message
  ///
  /// Useful for info boxes, toasts, and notifications.
  void styledMessage(
    String message, {
    String icon = 'ℹ',
    StatTone tone = StatTone.info,
    bool bold = false,
  }) {
    final toneColor = _toneColor(tone, theme);
    final iconPart = '${theme.bold}$toneColor$icon${theme.reset}';
    final msgPart = bold ? '${theme.bold}$message${theme.reset}' : message;
    gutterLine('$iconPart $msgPart');
  }

  /// Writes a section header line: ├─ SectionName
  void sectionHeader(String name) {
    line(
        '${theme.gray}${style.borderConnector}${theme.reset} ${theme.dim}$name${theme.reset}');
  }

  /// Writes a progress bar line: │ ████████░░░░ 75%
  void progressBar(
    double ratio, {
    int width = 20,
    String filledChar = '█',
    String emptyChar = '░',
    bool showPercent = true,
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filled = (clamped * width).round();
    final bar =
        '${theme.accent}${filledChar * filled}${theme.reset}${theme.dim}${emptyChar * (width - filled)}${theme.reset}';
    if (showPercent) {
      final pct = (clamped * 100).round();
      gutterLine('$bar ${theme.dim}$pct%${theme.reset}');
    } else {
      gutterLine(bar);
    }
  }

  /// Writes a key-value pair line with colored value: │ key = value
  void keyValue(String key, String value, {String separator = '='}) {
    gutterLine(
        '${theme.highlight}$key${theme.reset} ${theme.dim}$separator${theme.reset} ${theme.selection}$value${theme.reset}');
  }

  /// Writes a bullet item line: │ • Item text
  void bulletItem(String content, {String bullet = '•'}) {
    gutterLine('${theme.dim}$bullet${theme.reset} $content');
  }

  /// Writes a numbered item line: │ 1. Item text
  void numberedItem(int number, String content) {
    gutterLine('${theme.dim}$number.${theme.reset} $content');
  }

  /// Writes a tree branch item: │ ├─ Item
  void treeBranch(String content, {bool isLast = false}) {
    final branch = isLast ? '└─' : '├─';
    gutterLine('${theme.gray}$branch${theme.reset} $content');
  }

  /// Writes an equation/conversion line: │ Label value → Label = value
  void equation({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    String direction = '→',
  }) {
    final numL = '${theme.selection}$leftValue${theme.reset}';
    final numR = '${theme.selection}$rightValue${theme.reset}';
    final labL = '${theme.highlight}$leftLabel${theme.reset}';
    final labR = '${theme.highlight}$rightLabel${theme.reset}';
    final arrow = '${theme.dim}$direction${theme.reset}';
    final eq = '${theme.dim}=${theme.reset}';
    gutterLine('$labL $numL $arrow $labR $eq $numR');
  }

  /// Writes a tooltip/help hint line: │ (press Enter to continue)
  void tooltipLine(String hint) {
    gutterLine('${theme.dim}($hint)${theme.reset}');
  }

  /// Writes a separator line within the frame: │ ──────────
  void separatorLine({int width = 20}) {
    gutterLine('${theme.gray}${'─' * width}${theme.reset}');
  }

  /// Writes a blank line with optional filler character.
  void fillerLine({String? char}) {
    if (char != null) {
      gutterLine('${theme.dim}$char${theme.reset}');
    } else {
      gutterEmpty();
    }
  }
}

/// Tone for stat/styled items.
enum StatTone { info, warn, error, accent, success, neutral }

String _toneColor(StatTone tone, PromptTheme theme) {
  switch (tone) {
    case StatTone.info:
      return theme.info;
    case StatTone.warn:
      return theme.warn;
    case StatTone.error:
      return theme.error;
    case StatTone.accent:
      return theme.accent;
    case StatTone.success:
      return theme.checkboxOn;
    case StatTone.neutral:
      return theme.gray;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DISPLAY-ONLY EXTENSIONS
// ════════════════════════════════════════════════════════════════════════════

/// Extension methods for display-only (non-interactive) widget rendering.
extension WidgetFrameDisplay on WidgetFrame {
  /// Renders to stdout and returns immediately.
  ///
  /// Use for display-only widgets that don't need interactivity.
  /// Creates a RenderOutput internally and renders the frame.
  ///
  /// Example:
  /// ```dart
  /// final frame = WidgetFrame(title: 'Stats', theme: theme);
  /// frame.show((ctx) {
  ///   ctx.statItem('Tests', '98%', icon: '✔', tone: StatTone.success);
  ///   ctx.statItem('Coverage', '85%', icon: '◎', tone: StatTone.info);
  /// });
  /// ```
  void show(void Function(FrameContext ctx) content) {
    final out = RenderOutput();
    render(out, content);
  }

  /// Renders to a provided RenderOutput without interaction.
  ///
  /// Useful when you need to compose display-only frames with other outputs.
  void showTo(RenderOutput out, void Function(FrameContext ctx) content) {
    render(out, content);
  }

  /// Renders content only (no frame borders) to a provided RenderOutput.
  ///
  /// Useful for embedding content within other frames or custom layouts.
  void showContentTo(
      RenderOutput out, void Function(FrameContext ctx) content) {
    final frame = FramedLayout(title, theme: theme);
    final lb = LineBuilder(theme);
    final ctx = FrameContext._(out, lb, theme, frame);
    content(ctx);
  }
}

/// Extension to simplify WidgetFrame usage with PromptRunner.
extension WidgetFrameExtension on PromptRunner {
  /// Runs a prompt with WidgetFrame-based rendering.
  ///
  /// Convenience method that combines PromptRunner with WidgetFrame
  /// for the most common use case.
  ///
  /// Example:
  /// ```dart
  /// final runner = PromptRunner();
  /// final result = runner.runWithFrame(
  ///   frame: WidgetFrame(title: 'My Prompt', theme: theme, bindings: bindings),
  ///   content: (ctx) {
  ///     ctx.gutterLine('Content here');
  ///   },
  ///   bindings: bindings,
  /// );
  /// ```
  PromptResult runWithFrame({
    required WidgetFrame frame,
    required void Function(FrameContext ctx) content,
    required KeyBindings bindings,
  }) {
    return runWithBindings(
      render: (out) => frame.render(out, content),
      bindings: bindings,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INLINE WIDGET SUPPORT
// ════════════════════════════════════════════════════════════════════════════

/// InlineStyle – theme-aware inline text styling utilities.
///
/// Use for inline widgets that return styled strings rather than rendering
/// to output (badges, labels, status indicators).
///
/// Example:
/// ```dart
/// final inline = InlineStyle(theme);
/// stdout.writeln('Status: ${inline.badge("SUCCESS", tone: BadgeTone.success)}');
/// stdout.writeln('Build ${inline.spinner(phase)} Processing...');
/// ```
class InlineStyle {
  final PromptTheme theme;

  const InlineStyle(this.theme);

  // ──────────────────────────────────────────────────────────────────────────
  // BADGE STYLING
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an inline badge string: [ SUCCESS ]
  String badge(
    String text, {
    BadgeTone tone = BadgeTone.info,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) {
    final color = _badgeToneColor(tone);
    final label = ' $text ';

    if (bracketed) {
      if (inverted) {
        final body = '[$label]';
        return '${bold ? theme.bold : ''}${theme.inverse}$color$body${theme.reset}';
      }
      final inner = '${bold ? theme.bold : ''}$color$label${theme.reset}';
      return '[$inner]';
    }

    if (inverted) {
      return '${bold ? theme.bold : ''}${theme.inverse}$color$label${theme.reset}';
    }
    return '${bold ? theme.bold : ''}$color$label${theme.reset}';
  }

  /// Shorthand for success badge.
  String successBadge(String text) => badge(text, tone: BadgeTone.success);

  /// Shorthand for info badge.
  String infoBadge(String text) => badge(text, tone: BadgeTone.info);

  /// Shorthand for warning badge.
  String warnBadge(String text) => badge(text, tone: BadgeTone.warning);

  /// Shorthand for danger badge.
  String dangerBadge(String text) => badge(text, tone: BadgeTone.danger);

  // ──────────────────────────────────────────────────────────────────────────
  // SPINNER FRAMES
  // ──────────────────────────────────────────────────────────────────────────

  static const List<String> dotsFrames = [
    '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'
  ];
  static const List<String> barsFrames = [
    '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█', '▇', '▆', '▅', '▄', '▃', '▂'
  ];
  static const List<String> arcsFrames = ['◜', '◠', '◝', '◞', '◡', '◟'];

  /// Returns a spinner frame for the given phase.
  String spinner(int phase, {SpinnerFrames frames = SpinnerFrames.dots}) {
    final list = _spinnerFramesList(frames);
    final char = list[phase % list.length];
    final color = (phase % 2 == 0) ? theme.accent : theme.highlight;
    return '${theme.bold}$color$char${theme.reset}';
  }

  List<String> _spinnerFramesList(SpinnerFrames f) {
    switch (f) {
      case SpinnerFrames.dots:
        return dotsFrames;
      case SpinnerFrames.bars:
        return barsFrames;
      case SpinnerFrames.arcs:
        return arcsFrames;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INLINE TEXT STYLING
  // ──────────────────────────────────────────────────────────────────────────

  /// Applies accent color to text.
  String accent(String text) => '${theme.accent}$text${theme.reset}';

  /// Applies highlight color to text.
  String highlight(String text) => '${theme.highlight}$text${theme.reset}';

  /// Applies selection color to text.
  String selection(String text) => '${theme.selection}$text${theme.reset}';

  /// Applies dim styling to text.
  String dim(String text) => '${theme.dim}$text${theme.reset}';

  /// Applies bold styling to text.
  String bold(String text) => '${theme.bold}$text${theme.reset}';

  /// Applies gray color to text.
  String gray(String text) => '${theme.gray}$text${theme.reset}';

  /// Applies info color to text.
  String info(String text) => '${theme.info}$text${theme.reset}';

  /// Applies warn color to text.
  String warn(String text) => '${theme.warn}$text${theme.reset}';

  /// Applies error color to text.
  String error(String text) => '${theme.error}$text${theme.reset}';

  /// Applies inverse styling to text.
  String inverse(String text) => '${theme.inverse}$text${theme.reset}';

  // ──────────────────────────────────────────────────────────────────────────
  // INLINE ICONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a styled icon with the given tone color.
  String icon(String char, {StatTone tone = StatTone.accent}) {
    final color = _toneColor(tone, theme);
    return '${theme.bold}$color$char${theme.reset}';
  }

  /// Success icon (✔).
  String successIcon() => icon('✔', tone: StatTone.success);

  /// Error icon (✖).
  String errorIcon() => icon('✖', tone: StatTone.error);

  /// Warning icon (⚠).
  String warnIcon() => icon('⚠', tone: StatTone.warn);

  /// Info icon (ℹ).
  String infoIcon() => icon('ℹ', tone: StatTone.info);

  // ──────────────────────────────────────────────────────────────────────────
  // PROGRESS INDICATORS
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates an inline progress bar: ████░░░░ 75%
  String progressBar(
    double ratio, {
    int width = 10,
    bool showPercent = true,
    String filledChar = '█',
    String emptyChar = '░',
  }) {
    final clamped = ratio.clamp(0.0, 1.0);
    final filled = (clamped * width).round();
    final bar =
        '${theme.accent}${filledChar * filled}${theme.reset}${theme.dim}${emptyChar * (width - filled)}${theme.reset}';
    if (showPercent) {
      final pct = (clamped * 100).round();
      return '$bar ${dim('$pct%')}';
    }
    return bar;
  }

  String _badgeToneColor(BadgeTone tone) {
    switch (tone) {
      case BadgeTone.neutral:
        return theme.gray;
      case BadgeTone.info:
        return theme.accent;
      case BadgeTone.success:
        return theme.checkboxOn;
      case BadgeTone.warning:
        return theme.highlight;
      case BadgeTone.danger:
        return theme.highlight;
    }
  }
}

/// Badge tones for inline styling.
enum BadgeTone { neutral, info, success, warning, danger }

/// Spinner frame styles.
enum SpinnerFrames { dots, bars, arcs }

// ════════════════════════════════════════════════════════════════════════════
// ANIMATION SUPPORT
// ════════════════════════════════════════════════════════════════════════════

/// AnimatedFrame – runs an animation loop with frame-based rendering.
///
/// Simplifies creating animated widgets by handling:
/// - TerminalSession for cursor hiding
/// - RenderOutput for partial clearing
/// - Timing and frame control
///
/// Example:
/// ```dart
/// AnimatedFrame(
///   title: 'Loading',
///   theme: theme,
///   duration: Duration(seconds: 2),
///   fps: 12,
/// ).run((ctx, phase) {
///   final spin = InlineStyle(theme).spinner(phase);
///   ctx.gutterLine('Processing... $spin');
/// });
/// ```
class AnimatedFrame {
  final String title;
  final PromptTheme theme;
  final Duration duration;
  final int fps;
  final bool clearOnEnd;
  final List<String>? hints;

  AnimatedFrame({
    required this.title,
    required this.theme,
    this.duration = const Duration(seconds: 2),
    this.fps = 12,
    this.clearOnEnd = true,
    this.hints,
  }) : assert(fps > 0);

  /// Runs the animation loop.
  ///
  /// [content] receives the FrameContext and current frame phase.
  void run(void Function(FrameContext ctx, int phase) content) {
    final int frameMs = (1000 / fps).clamp(12, 200).round();

    void render(RenderOutput out, int phase) {
      final frame = WidgetFrame(title: title, theme: theme);
      frame.showTo(out, (ctx) => content(ctx, phase));

      if (hints != null && hints!.isNotEmpty) {
        out.writeln(Hints.bullets(hints!, theme, dim: true));
      }
    }

    TerminalSession(hideCursor: true).runWithOutput((out) {
      final sw = Stopwatch()..start();
      int phase = 0;

      render(out, phase);
      phase++;

      while (sw.elapsed < duration) {
        sleep(Duration(milliseconds: frameMs));
        out.clear();
        render(out, phase);
        phase++;
      }
    }, clearOnEnd: clearOnEnd);
  }

  /// Runs an indefinite animation until [stop] is called.
  ///
  /// Returns a controller to stop the animation.
  AnimationController runIndefinite(
      void Function(FrameContext ctx, int phase) content) {
    final controller = AnimationController._();
    final int frameMs = (1000 / fps).clamp(12, 200).round();

    void render(RenderOutput out, int phase) {
      final frame = WidgetFrame(title: title, theme: theme);
      frame.showTo(out, (ctx) => content(ctx, phase));

      if (hints != null && hints!.isNotEmpty) {
        out.writeln(Hints.bullets(hints!, theme, dim: true));
      }
    }

    // Run in async context to allow stopping
    Future<void>.microtask(() {
      TerminalSession(hideCursor: true).runWithOutput((out) {
        int phase = 0;
        render(out, phase);
        phase++;

        while (!controller._stopped) {
          sleep(Duration(milliseconds: frameMs));
          out.clear();
          render(out, phase);
          phase++;
        }
      }, clearOnEnd: clearOnEnd);
    });

    return controller;
  }
}

/// Controller for indefinite animations.
class AnimationController {
  bool _stopped = false;

  AnimationController._();

  /// Stops the animation.
  void stop() {
    _stopped = true;
  }

  /// Whether the animation has been stopped.
  bool get isStopped => _stopped;
}

// ════════════════════════════════════════════════════════════════════════════
// PERSISTENT STATUS LINE
// ════════════════════════════════════════════════════════════════════════════

/// PersistentLine – renders a persistent status line at the bottom of the terminal.
///
/// Uses the InlineStyle system for consistent theming.
///
/// Example:
/// ```dart
/// final status = PersistentLine(label: 'Build', theme: theme)..start();
/// status.update('Compiling sources');
/// status.success('Done');
/// status.stop();
/// ```
class PersistentLine {
  final String label;
  final PromptTheme theme;
  final bool showSpinner;
  final Duration spinnerInterval;

  late final InlineStyle _inline;
  Timer? _spinnerTimer;
  int _spinnerPhase = 0;
  String _message = '';
  bool _running = false;

  PersistentLine({
    required this.label,
    this.theme = PromptTheme.dark,
    this.showSpinner = true,
    this.spinnerInterval = const Duration(milliseconds: 120),
  }) {
    _inline = InlineStyle(theme);
  }

  /// Begin rendering the persistent status line.
  void start() {
    if (_running) return;
    _running = true;
    _render();
    if (showSpinner) {
      _spinnerTimer = Timer.periodic(spinnerInterval, (_) {
        _spinnerPhase++;
        _render();
      });
    }
  }

  /// Update the message on the status line.
  void update(String message) {
    _message = message;
    _render();
  }

  /// Show a success state and freeze the spinner.
  void success(String message) {
    _message = message;
    _render(icon: _inline.successIcon());
    _stopSpinner();
  }

  /// Show an error state and freeze the spinner.
  void error(String message) {
    _message = message;
    _render(icon: _inline.errorIcon());
    _stopSpinner();
  }

  /// Show a warning state.
  void warning(String message) {
    _message = message;
    _render(icon: _inline.warnIcon());
    _stopSpinner();
  }

  /// Stop rendering (does not clear the last line).
  void stop() {
    _stopSpinner();
    _running = false;
  }

  void _stopSpinner() {
    _spinnerTimer?.cancel();
    _spinnerTimer = null;
  }

  void _render({String? icon}) {
    if (!_running) return;
    final s = theme.style;

    final prefix = _inline.gray(s.borderBottom);
    final title = _inline.selection(' $label ');
    final spin = icon ?? (showSpinner ? _inline.spinner(_spinnerPhase) : ' ');
    final msg = _message.isEmpty ? '' : _inline.gray(_message);

    final line = StringBuffer()
      ..write(prefix)
      ..write(' ')
      ..write(title)
      ..write('  ')
      ..write(spin)
      ..write('  ')
      ..write(msg);

    _writeBottom(line.toString());
  }

  void _writeBottom(String text) {
    stdout.write('\x1B7'); // Save cursor
    stdout.write('\x1B[999;1H'); // Move to bottom
    stdout
      ..write('\x1B[2K') // Clear line
      ..writeln(text);
    stdout.write('\x1B8'); // Restore cursor
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SYNTAX HIGHLIGHTING SUPPORT
// ════════════════════════════════════════════════════════════════════════════

/// SyntaxHighlighter – theme-aware syntax highlighting utilities.
///
/// Use for highlighting code snippets within framed content.
class SyntaxHighlighter {
  final PromptTheme theme;

  const SyntaxHighlighter(this.theme);

  /// Highlights a line of Dart code.
  String dartLine(String line) {
    var out = line;

    // Line comments
    final commentIdx = out.indexOf('//');
    String? commentPart;
    if (commentIdx >= 0) {
      commentPart = out.substring(commentIdx);
      out = out.substring(0, commentIdx);
    }

    // Strings
    out = out.replaceAllMapped(
      RegExp(r'"[^"]*"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Numbers
    out = out.replaceAllMapped(
      RegExp(r'\b\d+(?:\.\d+)?\b'),
      (m) => '${theme.selection}${m[0]}${theme.reset}',
    );

    // Keywords
    const keywords = [
      'class', 'enum', 'import', 'as', 'show', 'hide', 'void', 'final',
      'const', 'var', 'return', 'if', 'else', 'for', 'while', 'switch',
      'case', 'break', 'continue', 'try', 'catch', 'on', 'throw', 'new',
      'this', 'super', 'extends', 'with', 'implements', 'static', 'get',
      'set', 'async', 'await', 'yield', 'true', 'false', 'null'
    ];
    final kwPattern = RegExp(r'\b(' + keywords.join('|') + r')\b');
    out = out.replaceAllMapped(
      kwPattern,
      (m) => '${theme.accent}${theme.bold}${m[0]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\[\]\{\}\(\)\,\;\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }

  /// Highlights a line of JSON.
  String jsonLine(String line) {
    var out = line;

    // Keys
    out = out.replaceAllMapped(
      RegExp(r'(\")([^\"]+)(\"\s*:)'),
      (m) => '${m[1]}${theme.accent}${theme.bold}${m[2]}${theme.reset}${m[3]}',
    );

    // String values
    out = out.replaceAllMapped(
      RegExp(r'(:\s*)(\"[^\"]*\")'),
      (m) => '${m[1]}${theme.highlight}${m[2]}${theme.reset}',
    );

    // Numbers, booleans, null
    out = out.replaceAllMapped(
      RegExp(r'(:\s*)(-?\d+(?:\.\d+)?|true|false|null)\b'),
      (m) => '${m[1]}${theme.selection}${m[2]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\[\]\{\}\,\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );

    return out;
  }

  /// Highlights a line of shell/bash.
  String shellLine(String line) {
    var out = line;

    // Full-line comment
    if (out.trimLeft().startsWith('#')) {
      return '${theme.gray}$out${theme.reset}';
    }

    // Partial comment
    final hash = out.indexOf('#');
    String? commentPart;
    if (hash > 0) {
      commentPart = out.substring(hash);
      out = out.substring(0, hash);
    }

    // Flags
    out = out.replaceAllMapped(
      RegExp(r'(\s|^)(--?[A-Za-z0-9][A-Za-z0-9\-]*)'),
      (m) => '${m[1]}${theme.accent}${m[2]}${theme.reset}',
    );

    // Strings
    out = out.replaceAllMapped(
      RegExp(r'"[^"]*"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Paths
    out = out.replaceAllMapped(
      RegExp(r'(/[^\s]+)'),
      (m) => '${theme.selection}${m[1]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }

  /// Auto-detects language and highlights.
  String autoLine(String line) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return jsonLine(line);
    if (trimmed.startsWith('#')) return shellLine(line);
    if (trimmed.startsWith('import ') || trimmed.contains(' void ') ||
        trimmed.contains(' class ') || trimmed.contains(' final ') ||
        trimmed.contains(' const ')) {
      return dartLine(line);
    }
    return line;
  }
}
