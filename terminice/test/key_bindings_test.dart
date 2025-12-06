import 'package:test/test.dart';
import 'package:terminice/src/system/key_bindings.dart';
import 'package:terminice/src/system/prompt_runner.dart';
import 'package:terminice/src/style/theme.dart';

void main() {
  group('KeyBinding', () {
    group('matches', () {
      test('matches single key type', () {
        final binding = KeyBinding.single(
          KeyEventType.enter,
          (_) => KeyActionResult.confirmed,
        );

        expect(binding.matches(const KeyEvent(KeyEventType.enter)), true);
        expect(binding.matches(const KeyEvent(KeyEventType.esc)), false);
      });

      test('matches multiple key types', () {
        final binding = KeyBinding.multi(
          {KeyEventType.esc, KeyEventType.ctrlC},
          (_) => KeyActionResult.cancelled,
        );

        expect(binding.matches(const KeyEvent(KeyEventType.esc)), true);
        expect(binding.matches(const KeyEvent(KeyEventType.ctrlC)), true);
        expect(binding.matches(const KeyEvent(KeyEventType.enter)), false);
      });

      test('matches character with predicate', () {
        final binding = KeyBinding.char(
          (c) => c == 'a' || c == 'A',
          (_) => KeyActionResult.handled,
        );

        expect(binding.matches(const KeyEvent(KeyEventType.char, 'a')), true);
        expect(binding.matches(const KeyEvent(KeyEventType.char, 'A')), true);
        expect(binding.matches(const KeyEvent(KeyEventType.char, 'b')), false);
        expect(binding.matches(const KeyEvent(KeyEventType.enter)), false);
      });
    });

    group('tryHandle', () {
      test('returns action result when matched', () {
        var called = false;
        final binding = KeyBinding.single(
          KeyEventType.enter,
          (_) {
            called = true;
            return KeyActionResult.confirmed;
          },
        );

        final result = binding.tryHandle(const KeyEvent(KeyEventType.enter));
        expect(result, KeyActionResult.confirmed);
        expect(called, true);
      });

      test('returns null when not matched', () {
        final binding = KeyBinding.single(
          KeyEventType.enter,
          (_) => KeyActionResult.confirmed,
        );

        final result = binding.tryHandle(const KeyEvent(KeyEventType.esc));
        expect(result, null);
      });
    });
  });

  group('KeyBindings', () {
    group('composition', () {
      test('combines bindings with + operator', () {
        final a = KeyBindings([
          KeyBinding.single(
              KeyEventType.enter, (_) => KeyActionResult.confirmed),
        ]);
        final b = KeyBindings([
          KeyBinding.single(KeyEventType.esc, (_) => KeyActionResult.cancelled),
        ]);

        final combined = a + b;
        expect(combined.bindings.length, 2);
      });

      test('merges multiple collections', () {
        final a = KeyBindings([
          KeyBinding.single(
              KeyEventType.enter, (_) => KeyActionResult.confirmed),
        ]);
        final b = KeyBindings([
          KeyBinding.single(KeyEventType.esc, (_) => KeyActionResult.cancelled),
        ]);
        final c = KeyBindings([
          KeyBinding.single(KeyEventType.space, (_) => KeyActionResult.handled),
        ]);

        final merged = KeyBindings.merge([a, b, c]);
        expect(merged.bindings.length, 3);
      });

      test('add creates new collection with additional binding', () {
        final bindings = KeyBindings([
          KeyBinding.single(
              KeyEventType.enter, (_) => KeyActionResult.confirmed),
        ]);

        final extended = bindings.add(
          KeyBinding.single(KeyEventType.esc, (_) => KeyActionResult.cancelled),
        );

        expect(bindings.bindings.length, 1); // Original unchanged
        expect(extended.bindings.length, 2);
      });
    });

    group('handle', () {
      test('returns first matching result', () {
        final bindings = KeyBindings([
          KeyBinding.single(
              KeyEventType.enter, (_) => KeyActionResult.confirmed),
          KeyBinding.single(KeyEventType.esc, (_) => KeyActionResult.cancelled),
        ]);

        expect(
          bindings.handle(const KeyEvent(KeyEventType.enter)),
          KeyActionResult.confirmed,
        );
        expect(
          bindings.handle(const KeyEvent(KeyEventType.esc)),
          KeyActionResult.cancelled,
        );
      });

      test('returns ignored when no binding matches', () {
        final bindings = KeyBindings([
          KeyBinding.single(
              KeyEventType.enter, (_) => KeyActionResult.confirmed),
        ]);

        expect(
          bindings.handle(const KeyEvent(KeyEventType.esc)),
          KeyActionResult.ignored,
        );
      });

      test('skips ignored results and continues to next binding', () {
        final bindings = KeyBindings([
          KeyBinding.single(KeyEventType.enter, (_) => KeyActionResult.ignored),
          KeyBinding.single(
              KeyEventType.enter, (_) => KeyActionResult.confirmed),
        ]);

        expect(
          bindings.handle(const KeyEvent(KeyEventType.enter)),
          KeyActionResult.confirmed,
        );
      });
    });

    group('toPromptResult', () {
      test('converts confirmed to PromptResult.confirmed', () {
        expect(
          KeyBindings.toPromptResult(KeyActionResult.confirmed),
          PromptResult.confirmed,
        );
      });

      test('converts cancelled to PromptResult.cancelled', () {
        expect(
          KeyBindings.toPromptResult(KeyActionResult.cancelled),
          PromptResult.cancelled,
        );
      });

      test('converts handled to null', () {
        expect(KeyBindings.toPromptResult(KeyActionResult.handled), null);
      });

      test('converts ignored to null', () {
        expect(KeyBindings.toPromptResult(KeyActionResult.ignored), null);
      });
    });

    group('hint generation', () {
      test('toHintEntries returns labels and descriptions', () {
        final bindings = KeyBindings([
          KeyBinding.single(
            KeyEventType.enter,
            (_) => KeyActionResult.confirmed,
            hintLabel: 'Enter',
            hintDescription: 'confirm',
          ),
          KeyBinding.single(
            KeyEventType.esc,
            (_) => KeyActionResult.cancelled,
            hintLabel: 'Esc',
            hintDescription: 'cancel',
          ),
        ]);

        final entries = bindings.toHintEntries();
        expect(entries.length, 2);
        expect(entries[0], ['Enter', 'confirm']);
        expect(entries[1], ['Esc', 'cancel']);
      });

      test('toHintEntries skips bindings without hints', () {
        final bindings = KeyBindings([
          KeyBinding.single(
            KeyEventType.enter,
            (_) => KeyActionResult.confirmed,
            hintLabel: 'Enter',
            hintDescription: 'confirm',
          ),
          KeyBinding.single(
            KeyEventType.arrowUp,
            (_) => KeyActionResult.handled,
            // No hints
          ),
        ]);

        final entries = bindings.toHintEntries();
        expect(entries.length, 1);
      });

      test('toHintsBullets generates bullet string', () {
        const theme = PromptTheme.dark;
        final bindings = KeyBindings([
          KeyBinding.single(
            KeyEventType.enter,
            (_) => KeyActionResult.confirmed,
            hintLabel: 'Enter',
            hintDescription: 'confirm',
          ),
        ]);

        final bullets = bindings.toHintsBullets(theme);
        expect(bullets.contains('Enter'), true);
        expect(bullets.contains('confirm'), true);
      });
    });
  });

  group('Standard bindings factories', () {
    test('cancel creates Esc/Ctrl+C binding', () {
      var cancelled = false;
      final bindings = KeyBindings.cancel(onCancel: () => cancelled = true);

      bindings.handle(const KeyEvent(KeyEventType.esc));
      expect(cancelled, true);

      cancelled = false;
      bindings.handle(const KeyEvent(KeyEventType.ctrlC));
      expect(cancelled, true);
    });

    test('confirm creates Enter binding', () {
      final bindings = KeyBindings.confirm();

      expect(
        bindings.handle(const KeyEvent(KeyEventType.enter)),
        KeyActionResult.confirmed,
      );
    });

    test('verticalNavigation creates up/down bindings', () {
      var upCount = 0;
      var downCount = 0;
      final bindings = KeyBindings.verticalNavigation(
        onUp: () => upCount++,
        onDown: () => downCount++,
      );

      bindings.handle(const KeyEvent(KeyEventType.arrowUp));
      expect(upCount, 1);

      bindings.handle(const KeyEvent(KeyEventType.arrowDown));
      expect(downCount, 1);
    });

    test('horizontalNavigation creates left/right bindings', () {
      var leftCount = 0;
      var rightCount = 0;
      final bindings = KeyBindings.horizontalNavigation(
        onLeft: () => leftCount++,
        onRight: () => rightCount++,
      );

      bindings.handle(const KeyEvent(KeyEventType.arrowLeft));
      expect(leftCount, 1);

      bindings.handle(const KeyEvent(KeyEventType.arrowRight));
      expect(rightCount, 1);
    });

    test('toggle creates Space binding', () {
      var toggled = false;
      final bindings = KeyBindings.toggle(onToggle: () => toggled = !toggled);

      bindings.handle(const KeyEvent(KeyEventType.space));
      expect(toggled, true);

      bindings.handle(const KeyEvent(KeyEventType.space));
      expect(toggled, false);
    });

    test('numbers creates number key bindings', () {
      int? received;
      final bindings = KeyBindings.numbers(
        onNumber: (n) => received = n,
        max: 5,
      );

      bindings.handle(const KeyEvent(KeyEventType.char, '3'));
      expect(received, 3);

      // Beyond max - should be ignored
      received = null;
      bindings.handle(const KeyEvent(KeyEventType.char, '8'));
      expect(received, null);
    });

    test('letter creates specific letter binding', () {
      var pressed = false;
      final bindings = KeyBindings.letter(
        char: 'A',
        onPress: () => pressed = true,
      );

      bindings.handle(const KeyEvent(KeyEventType.char, 'a'));
      expect(pressed, true);

      pressed = false;
      bindings.handle(const KeyEvent(KeyEventType.char, 'A'));
      expect(pressed, true);

      pressed = false;
      bindings.handle(const KeyEvent(KeyEventType.char, 'b'));
      expect(pressed, false);
    });
  });

  group('Preset bindings', () {
    test('prompt combines confirm and cancel', () {
      final bindings = KeyBindings.prompt();

      expect(
        bindings.handle(const KeyEvent(KeyEventType.enter)),
        KeyActionResult.confirmed,
      );
      expect(
        bindings.handle(const KeyEvent(KeyEventType.esc)),
        KeyActionResult.cancelled,
      );
    });

    test('list combines navigation, confirm, and cancel', () {
      var upCalled = false;
      var downCalled = false;
      final bindings = KeyBindings.list(
        onUp: () => upCalled = true,
        onDown: () => downCalled = true,
      );

      bindings.handle(const KeyEvent(KeyEventType.arrowUp));
      expect(upCalled, true);

      bindings.handle(const KeyEvent(KeyEventType.arrowDown));
      expect(downCalled, true);

      expect(
        bindings.handle(const KeyEvent(KeyEventType.enter)),
        KeyActionResult.confirmed,
      );
    });

    test('selection combines navigation, toggle, confirm, and cancel', () {
      var toggleCalled = false;
      final bindings = KeyBindings.selection(
        onUp: () {},
        onDown: () {},
        onToggle: () => toggleCalled = true,
      );

      bindings.handle(const KeyEvent(KeyEventType.space));
      expect(toggleCalled, true);
    });

    test('slider combines horizontal navigation, confirm, and cancel', () {
      var leftCalled = false;
      final bindings = KeyBindings.slider(
        onLeft: () => leftCalled = true,
        onRight: () {},
      );

      bindings.handle(const KeyEvent(KeyEventType.arrowLeft));
      expect(leftCalled, true);
    });

    test('togglePrompt handles all directions as toggle', () {
      var toggleCount = 0;
      final bindings = KeyBindings.togglePrompt(
        onToggle: () => toggleCount++,
      );

      bindings.handle(const KeyEvent(KeyEventType.arrowLeft));
      bindings.handle(const KeyEvent(KeyEventType.arrowRight));
      bindings.handle(const KeyEvent(KeyEventType.arrowUp));
      bindings.handle(const KeyEvent(KeyEventType.arrowDown));
      bindings.handle(const KeyEvent(KeyEventType.space));

      expect(toggleCount, 5);
    });
  });
}
