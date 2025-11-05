import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/hints.dart';

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

    final state = Terminal.enterRaw();
    Terminal.hideCursor();
    try {
      var flipped = false;
      CardItem? current = _nextDueCard();
      while (true) {
        Terminal.clearAndHome();
        _renderHeader();
        if (current == null) {
          _line('${theme.info}Session complete. No due cards.${theme.reset}');
          _line(_summaryLine());
          if (theme.style.showBorder) {
            stdout.writeln(FrameRenderer.bottomLine(title, theme));
          }
          break;
        }

        _renderCard(current, flipped: flipped);
        _renderHints(flipped: flipped);

        final ev = KeyEventReader.read();
        if (ev.type == KeyEventType.esc ||
            ev.type == KeyEventType.ctrlC ||
            (ev.type == KeyEventType.char && ev.char == 'q')) {
          Terminal.clearAndHome();
          _renderHeader();
          _line('${theme.warn}Session ended by user.${theme.reset}');
          _line(_summaryLine());
          if (theme.style.showBorder) {
            stdout.writeln(FrameRenderer.bottomLine(title, theme));
          }
          break;
        }

        if (ev.type == KeyEventType.space ||
            (ev.type == KeyEventType.char && ev.char == 'f')) {
          flipped = !flipped;
          continue;
        }

        if (ev.type == KeyEventType.char) {
          final ch = ev.char!;
          if (RegExp(r'^[1-5]$').hasMatch(ch)) {
            if (!flipped) {
              // First numeric press reveals the answer for quick flow.
              flipped = true;
              continue;
            }
            final score = int.parse(ch);
            _grade(current, score);
            totalReviews += 1;
            if (score >= 4) correctReviews += 1;
            flipped = false;
            current = _nextDueCard();
            continue;
          }
        }

        if (ev.type == KeyEventType.arrowRight ||
            (ev.type == KeyEventType.char && ev.char == 'n')) {
          flipped = false;
          current = _nextDueCard(skipCurrent: current);
          continue;
        }
      }
    } finally {
      Terminal.showCursor();
      state.restore();
    }
  }

  void _renderHeader() {
    final style = theme.style;
    final top = style.showBorder
        ? FrameRenderer.titleWithBorders(title, theme)
        : FrameRenderer.plainTitle(title, theme);
    stdout.writeln('${theme.bold}$top${theme.reset}');
    _line(_summaryLine());
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

  void _renderCard(CardItem card, {required bool flipped}) {
    final face = flipped ? card.back : card.front;
    final label = flipped ? 'Answer' : 'Question';
    final color = flipped ? theme.accent : theme.highlight;
    _section('${label}');
    for (final line in face.split('\n')) {
      _line('$color$line${theme.reset}');
    }

    if (!flipped && card.hint != null && card.hint!.isNotEmpty) {
      _section('Hint');
      _line('${theme.gray}${card.hint}${theme.reset}');
    }
  }

  void _renderHints({required bool flipped}) {
    stdout.writeln();
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
      _line(line);
    }
    if (theme.style.showBorder) {
      stdout.writeln(FrameRenderer.bottomLine(title, theme));
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

  void _line(String content) {
    if (content.trim().isEmpty) return;
    final s = theme.style;
    stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset} $content');
  }

  void _section(String name) {
    final s = theme.style;
    final header = '${theme.bold}${theme.accent}$name${theme.reset}';
    stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset} $header');
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
