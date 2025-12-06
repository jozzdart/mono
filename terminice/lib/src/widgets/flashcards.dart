import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/line_builder.dart';
import '../system/rendering.dart';
import '../system/prompt_runner.dart';

/// Flashcards – spaced repetition deck in terminal.
///
/// Aligns with ThemeDemo styling via themed title bar, left gutter,
/// accent/highlight colors, and bottom border.
class Flashcards {
  final PromptTheme theme;
  final String title;
  final List<CardItem> deck;

  // Session state
  int totalReviews = 0;
  int correctReviews = 0;
  DateTime startedAt = DateTime.now();

  Flashcards({
    required List<CardItem> cards,
    this.theme = const PromptTheme(),
    this.title = 'Flashcards',
  }) : deck = List<CardItem>.from(cards);

  /// Starts an interactive study session.
  void run() {
    if (deck.isEmpty) {
      stdout.writeln('${theme.warn}No cards in deck.${theme.reset}');
      return;
    }

    var flipped = false;
    CardItem? current = _nextDueCard();
    bool userQuit = false;

    void render(RenderOutput out) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);

      _renderHeader(out);
      if (current == null) {
        out.writeln('${lb.gutter()}${theme.info}Session complete. No due cards.${theme.reset}');
        out.writeln('${lb.gutter()}${_summaryLine()}');
        if (theme.style.showBorder) {
          final frame = FramedLayout(title, theme: theme);
          out.writeln(frame.bottom());
        }
        return;
      }

      if (userQuit) {
        out.writeln('${lb.gutter()}${theme.warn}Session ended by user.${theme.reset}');
        out.writeln('${lb.gutter()}${_summaryLine()}');
        if (theme.style.showBorder) {
          final frame = FramedLayout(title, theme: theme);
          out.writeln(frame.bottom());
        }
        return;
      }

      _renderCard(out, current!, flipped: flipped);
      _renderHints(out, flipped: flipped);
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (current == null) {
          return PromptResult.confirmed;
        }

        if (ev.type == KeyEventType.esc ||
            ev.type == KeyEventType.ctrlC ||
            (ev.type == KeyEventType.char && ev.char == 'q')) {
          userQuit = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.space ||
            (ev.type == KeyEventType.char && ev.char == 'f')) {
          flipped = !flipped;
          return null;
        }

        if (ev.type == KeyEventType.char) {
          final ch = ev.char!;
          if (RegExp(r'^[1-5]$').hasMatch(ch)) {
            if (!flipped) {
              // First numeric press reveals the answer for quick flow.
              flipped = true;
              return null;
            }
            final score = int.parse(ch);
            _grade(current!, score);
            totalReviews += 1;
            if (score >= 4) correctReviews += 1;
            flipped = false;
            current = _nextDueCard();
            if (current == null) {
              return PromptResult.confirmed;
            }
            return null;
          }
        }

        if (ev.type == KeyEventType.arrowRight ||
            (ev.type == KeyEventType.char && ev.char == 'n')) {
          flipped = false;
          current = _nextDueCard(skipCurrent: current);
          if (current == null) {
            return PromptResult.confirmed;
          }
          return null;
        }

        return null;
      },
    );
  }

  void _renderHeader(RenderOutput out) {
    final lb = LineBuilder(theme);
    final frame = FramedLayout(title, theme: theme);
    final top = frame.top();
    out.writeln('${theme.bold}$top${theme.reset}');
    out.writeln('${lb.gutter()}${_summaryLine()}');
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

  void _renderCard(RenderOutput out, CardItem card, {required bool flipped}) {
    final lb = LineBuilder(theme);
    final face = flipped ? card.back : card.front;
    final label = flipped ? 'Answer' : 'Question';
    final color = flipped ? theme.accent : theme.highlight;
    out.writeln('${lb.gutter()}${sectionHeader(theme, label)}');
    for (final line in face.split('\n')) {
      out.writeln('${lb.gutter()}$color$line${theme.reset}');
    }

    if (!flipped && card.hint != null && card.hint!.isNotEmpty) {
      out.writeln('${lb.gutter()}${sectionHeader(theme, 'Hint')}');
      out.writeln('${lb.gutter()}${theme.gray}${card.hint}${theme.reset}');
    }
  }

  void _renderHints(RenderOutput out, {required bool flipped}) {
    final lb = LineBuilder(theme);
    out.writeln('');
    final rows = <List<String>>[
      [Hints.key('Space', theme), flipped ? 'Hide answer' : 'Show answer'],
      [
        Hints.key('1-5', theme),
        'Grade (1 again … 5 easy; first press reveals)'
      ],
      [Hints.key('n', theme), 'Skip card'],
      [Hints.key('q', theme), 'Quit'],
    ];
    final s = Hints.grid(rows, theme).split('\n');
    for (final line in s) {
      out.writeln('${lb.gutter()}$line');
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
