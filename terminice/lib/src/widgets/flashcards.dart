import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/rendering.dart';
import '../system/widget_frame.dart';

/// Flashcards – spaced repetition deck in terminal.
///
/// Aligns with ThemeDemo styling via themed title bar, left gutter,
/// accent/highlight colors, and bottom border.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// Flashcards(cards: deck).withPastelTheme().run();
/// ```
class Flashcards with Themeable {
  @override
  final PromptTheme theme;
  final String title;
  final List<CardItem> deck;

  // Session state
  int totalReviews = 0;
  int correctReviews = 0;
  DateTime startedAt = DateTime.now();

  Flashcards({
    required List<CardItem> cards,
    this.theme = PromptTheme.dark,
    this.title = 'Flashcards',
  }) : deck = List<CardItem>.from(cards);

  @override
  Flashcards copyWithTheme(PromptTheme theme) {
    return Flashcards(
      cards: deck,
      theme: theme,
      title: title,
    );
  }

  /// Starts an interactive study session.
  void run() {
    if (deck.isEmpty) {
      stdout.writeln('${theme.warn}No cards in deck.${theme.reset}');
      return;
    }

    var flipped = false;
    CardItem? current = _nextDueCard();
    bool userQuit = false;

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // Quit
          KeyBinding.multi(
            {KeyEventType.esc},
            (event) {
              userQuit = true;
              return KeyActionResult.cancelled;
            },
            hintLabel: 'q',
            hintDescription: 'Quit',
          ),
          KeyBinding.char(
            (c) => c == 'q',
            (event) {
              userQuit = true;
              return KeyActionResult.cancelled;
            },
          ),
          // Flip card
          KeyBinding.single(
            KeyEventType.space,
            (event) {
              flipped = !flipped;
              return KeyActionResult.handled;
            },
            hintLabel: 'Space',
            hintDescription: 'Show/hide answer',
          ),
          KeyBinding.char(
            (c) => c == 'f',
            (event) {
              flipped = !flipped;
              return KeyActionResult.handled;
            },
          ),
          // Grade 1-5
          KeyBinding.char(
            (c) => RegExp(r'^[1-5]$').hasMatch(c),
            (event) {
              if (current == null) return KeyActionResult.confirmed;
              final ch = event.char!;
              if (!flipped) {
                // First numeric press reveals the answer for quick flow.
                flipped = true;
                return KeyActionResult.handled;
              }
              final score = int.parse(ch);
              _grade(current!, score);
              totalReviews += 1;
              if (score >= 4) correctReviews += 1;
              flipped = false;
              current = _nextDueCard();
              if (current == null) {
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
            hintLabel: '1-5',
            hintDescription: 'Grade (first press reveals)',
          ),
          // Skip card
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              flipped = false;
              current = _nextDueCard(skipCurrent: current);
              if (current == null) {
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
            hintLabel: 'n',
            hintDescription: 'Skip card',
          ),
          KeyBinding.char(
            (c) => c == 'n',
            (event) {
              flipped = false;
              current = _nextDueCard(skipCurrent: current);
              if (current == null) {
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
          ),
        ]) +
        KeyBindings.cancel(onCancel: () => userQuit = true);

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: null, // We handle hints manually for this complex widget
    );

    void render(RenderOutput out) {
      frame.renderContent(out, (ctx) {
        // Summary line
        ctx.gutterLine(_summaryLine());

        if (current == null) {
          ctx.infoMessage('Session complete. No due cards.');
          ctx.gutterLine(_summaryLine());
          return;
        }

        if (userQuit) {
          ctx.warnMessage('Session ended by user.');
          ctx.gutterLine(_summaryLine());
          return;
        }

        // Render card
        _renderCard(ctx, current!, flipped: flipped);
      });

      // Render hints (manually for complex layout)
      _renderHints(out, flipped: flipped, bindings: bindings);
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );
  }

  String _summaryLine() {
    final elapsed = DateTime.now().difference(startedAt);
    final mins = elapsed.inMinutes;
    final secs = elapsed.inSeconds % 60;
    final acc = totalReviews == 0
        ? '—'
        : '${((correctReviews / max(1, totalReviews)) * 100).round()}%';

    final due = deck.where((c) => c.isDue).length;
    return '${theme.dim}Due:${theme.reset} $due   '
        '${theme.dim}Reviewed:${theme.reset} $totalReviews   '
        '${theme.dim}Accuracy:${theme.reset} $acc   '
        '${theme.dim}Time:${theme.reset} ${mins}m ${secs}s';
  }

  void _renderCard(FrameContext ctx, CardItem card, {required bool flipped}) {
    final face = flipped ? card.back : card.front;
    final label = flipped ? 'Answer' : 'Question';
    final color = flipped ? theme.accent : theme.highlight;
    ctx.gutterLine(sectionHeader(theme, label));
    for (final line in face.split('\n')) {
      ctx.gutterLine('$color$line${theme.reset}');
    }

    if (!flipped && card.hint != null && card.hint!.isNotEmpty) {
      ctx.gutterLine(sectionHeader(theme, 'Hint'));
      ctx.gutterLine('${theme.gray}${card.hint}${theme.reset}');
    }
  }

  void _renderHints(RenderOutput out,
      {required bool flipped, required KeyBindings bindings}) {
    final lb = theme.style.borderVertical;
    out.writeln('');
    final s = Hints.grid(bindings.toHintEntries(), theme).split('\n');
    for (final line in s) {
      out.writeln('${theme.gray}$lb${theme.reset} $line');
    }
    if (theme.style.showBorder) {
      final frame = FramedLayout(title, theme: theme);
      out.writeln(frame.bottom());
    }
  }

  CardItem? _nextDueCard({CardItem? skipCurrent}) {
    final due = deck.where((c) => c.isDue && c != skipCurrent).toList();
    if (due.isEmpty) return null;
    due.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return due.first;
  }

  void _grade(CardItem card, int score) {
    // Simple Leitner system with demo-friendly seconds per box.
    // 1-2 → reset to box 1; 3 → stay; 4-5 → advance.
    final delays = <int, Duration>{
      1: const Duration(seconds: 10),
      2: const Duration(seconds: 30),
      3: const Duration(seconds: 60),
      4: const Duration(seconds: 120),
      5: const Duration(seconds: 300),
    };

    card.reviews += 1;
    if (score <= 2) {
      card.box = 1;
      card.lapses += 1;
    } else if (score >= 4) {
      card.box = min(5, card.box + 1);
      card.correct += 1;
    } // score == 3 → stay in box

    final wait = delays[card.box] ?? const Duration(seconds: 30);
    card.dueAt = DateTime.now().add(wait);
  }
}

class CardItem {
  final String front;
  final String back;
  final String? hint;

  int box;
  DateTime dueAt;
  int reviews;
  int correct;
  int lapses;

  CardItem({
    required this.front,
    required this.back,
    this.hint,
    this.box = 1,
    DateTime? dueAt,
    this.reviews = 0,
    this.correct = 0,
    this.lapses = 0,
  }) : dueAt = dueAt ?? DateTime.now();

  bool get isDue =>
      dueAt.isBefore(DateTime.now()) || dueAt.isAtSameMomentAs(DateTime.now());
}

/// Convenience function to start a flashcards session quickly.
void flashcards({
  required List<CardItem> cards,
  PromptTheme theme = const PromptTheme(),
  String title = 'Flashcards',
}) {
  Flashcards(cards: cards, theme: theme, title: title).run();
}
