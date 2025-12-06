import 'package:terminice/src/system/text_input_buffer.dart';
import 'package:terminice/src/system/key_events.dart';
import 'package:test/test.dart';

void main() {
  group('TextInputBuffer', () {
    group('initialization', () {
      test('starts empty by default', () {
        final buffer = TextInputBuffer();
        expect(buffer.text, isEmpty);
        expect(buffer.cursorPosition, 0);
        expect(buffer.isEmpty, isTrue);
      });

      test('accepts initial text', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        expect(buffer.text, 'hello');
        expect(buffer.cursorPosition, 5); // cursor at end
        expect(buffer.isNotEmpty, isTrue);
      });

      test('respects maxLength on initialization', () {
        final buffer = TextInputBuffer(
          initialText: 'hello world',
          maxLength: 5,
        );
        expect(buffer.text, 'hello');
        expect(buffer.length, 5);
      });
    });

    group('insert', () {
      test('inserts character at cursor', () {
        final buffer = TextInputBuffer();
        expect(buffer.insert('a'), isTrue);
        expect(buffer.text, 'a');
        expect(buffer.cursorPosition, 1);
      });

      test('inserts at cursor position', () {
        final buffer = TextInputBuffer(initialText: 'ac');
        buffer.setCursorPosition(1);
        buffer.insert('b');
        expect(buffer.text, 'abc');
        expect(buffer.cursorPosition, 2);
      });

      test('respects maxLength', () {
        final buffer = TextInputBuffer(maxLength: 3);
        buffer.insert('a');
        buffer.insert('b');
        buffer.insert('c');
        expect(buffer.insert('d'), isFalse);
        expect(buffer.text, 'abc');
      });

      test('returns false for empty string', () {
        final buffer = TextInputBuffer();
        expect(buffer.insert(''), isFalse);
      });
    });

    group('insertText', () {
      test('inserts multiple characters', () {
        final buffer = TextInputBuffer();
        final count = buffer.insertText('hello');
        expect(count, 5);
        expect(buffer.text, 'hello');
      });

      test('truncates to maxLength', () {
        final buffer = TextInputBuffer(maxLength: 5);
        final count = buffer.insertText('hello world');
        expect(count, 5);
        expect(buffer.text, 'hello');
      });

      test('inserts at cursor position', () {
        final buffer = TextInputBuffer(initialText: 'ad');
        buffer.setCursorPosition(1);
        buffer.insertText('bc');
        expect(buffer.text, 'abcd');
      });
    });

    group('backspace', () {
      test('deletes character before cursor', () {
        final buffer = TextInputBuffer(initialText: 'abc');
        expect(buffer.backspace(), isTrue);
        expect(buffer.text, 'ab');
        expect(buffer.cursorPosition, 2);
      });

      test('returns false at start', () {
        final buffer = TextInputBuffer(initialText: 'abc');
        buffer.moveCursorToStart();
        expect(buffer.backspace(), isFalse);
        expect(buffer.text, 'abc');
      });

      test('deletes in middle', () {
        final buffer = TextInputBuffer(initialText: 'abc');
        buffer.setCursorPosition(2);
        buffer.backspace();
        expect(buffer.text, 'ac');
        expect(buffer.cursorPosition, 1);
      });
    });

    group('delete', () {
      test('deletes character at cursor', () {
        final buffer = TextInputBuffer(initialText: 'abc');
        buffer.moveCursorToStart();
        expect(buffer.delete(), isTrue);
        expect(buffer.text, 'bc');
        expect(buffer.cursorPosition, 0);
      });

      test('returns false at end', () {
        final buffer = TextInputBuffer(initialText: 'abc');
        expect(buffer.delete(), isFalse);
        expect(buffer.text, 'abc');
      });
    });

    group('backspaceWord', () {
      test('deletes word before cursor', () {
        final buffer = TextInputBuffer(initialText: 'hello world');
        expect(buffer.backspaceWord(), isTrue);
        expect(buffer.text, 'hello ');
      });

      test('deletes trailing spaces and word', () {
        final buffer = TextInputBuffer(initialText: 'hello  ');
        buffer.backspaceWord();
        expect(buffer.text, '');
      });

      test('returns false at start', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.moveCursorToStart();
        expect(buffer.backspaceWord(), isFalse);
      });
    });

    group('clear', () {
      test('clears all text', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.clear();
        expect(buffer.text, isEmpty);
        expect(buffer.cursorPosition, 0);
      });
    });

    group('setText', () {
      test('replaces text entirely', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setText('world');
        expect(buffer.text, 'world');
        expect(buffer.cursorPosition, 5);
      });

      test('respects maxLength', () {
        final buffer = TextInputBuffer(maxLength: 5);
        buffer.setText('hello world');
        expect(buffer.text, 'hello');
      });
    });

    group('cursor movement', () {
      test('moveCursor moves by delta', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.moveCursor(-2);
        expect(buffer.cursorPosition, 3);
        buffer.moveCursor(1);
        expect(buffer.cursorPosition, 4);
      });

      test('moveCursor clamps to bounds', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.moveCursor(-100);
        expect(buffer.cursorPosition, 0);
        buffer.moveCursor(100);
        expect(buffer.cursorPosition, 5);
      });

      test('moveCursorToStart moves to 0', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.moveCursorToStart();
        expect(buffer.cursorPosition, 0);
      });

      test('moveCursorToEnd moves to length', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.moveCursorToStart();
        buffer.moveCursorToEnd();
        expect(buffer.cursorPosition, 5);
      });

      test('moveCursorWordLeft jumps to word boundary', () {
        final buffer = TextInputBuffer(initialText: 'hello world');
        buffer.moveCursorWordLeft();
        expect(buffer.cursorPosition, 6); // before 'world'
        buffer.moveCursorWordLeft();
        expect(buffer.cursorPosition, 0);
      });

      test('moveCursorWordRight jumps to word boundary', () {
        final buffer = TextInputBuffer(initialText: 'hello world');
        buffer.moveCursorToStart();
        buffer.moveCursorWordRight();
        expect(buffer.cursorPosition, 6); // after 'hello '
        buffer.moveCursorWordRight();
        expect(buffer.cursorPosition, 11);
      });
    });

    group('getters', () {
      test('textBeforeCursor returns text before cursor', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(3);
        expect(buffer.textBeforeCursor, 'hel');
      });

      test('textAfterCursor returns text after cursor', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(3);
        expect(buffer.textAfterCursor, 'lo');
      });

      test('charAtCursor returns character at cursor', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(2);
        expect(buffer.charAtCursor, 'l');
      });

      test('charAtCursor returns null at end', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        expect(buffer.charAtCursor, isNull);
      });

      test('cursorAtStart/cursorAtEnd', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        expect(buffer.cursorAtEnd, isTrue);
        expect(buffer.cursorAtStart, isFalse);
        buffer.moveCursorToStart();
        expect(buffer.cursorAtStart, isTrue);
        expect(buffer.cursorAtEnd, isFalse);
      });
    });

    group('handleKey', () {
      test('handles character input', () {
        final buffer = TextInputBuffer();
        final result = buffer.handleKey(const KeyEvent(KeyEventType.char, 'a'));
        expect(result, isTrue);
        expect(buffer.text, 'a');
      });

      test('handles space', () {
        final buffer = TextInputBuffer();
        buffer.handleKey(const KeyEvent(KeyEventType.space));
        expect(buffer.text, ' ');
      });

      test('handles backspace', () {
        final buffer = TextInputBuffer(initialText: 'ab');
        buffer.handleKey(const KeyEvent(KeyEventType.backspace));
        expect(buffer.text, 'a');
      });

      test('handles arrow left', () {
        final buffer = TextInputBuffer(initialText: 'ab');
        buffer.handleKey(const KeyEvent(KeyEventType.arrowLeft));
        expect(buffer.cursorPosition, 1);
      });

      test('handles arrow right', () {
        final buffer = TextInputBuffer(initialText: 'ab');
        buffer.moveCursorToStart();
        buffer.handleKey(const KeyEvent(KeyEventType.arrowRight));
        expect(buffer.cursorPosition, 1);
      });

      test('returns false for unhandled keys', () {
        final buffer = TextInputBuffer();
        expect(buffer.handleKey(const KeyEvent(KeyEventType.enter)), isFalse);
        expect(buffer.handleKey(const KeyEvent(KeyEventType.esc)), isFalse);
        expect(buffer.handleKey(const KeyEvent(KeyEventType.tab)), isFalse);
      });

      test('returns false when already at boundary', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        expect(
            buffer.handleKey(const KeyEvent(KeyEventType.arrowRight)), isFalse);

        buffer.moveCursorToStart();
        expect(
            buffer.handleKey(const KeyEvent(KeyEventType.arrowLeft)), isFalse);
      });
    });

    group('textWithCursor', () {
      test('shows cursor at position', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(2);
        expect(buffer.textWithCursor(cursorChar: '|'), 'he|llo');
      });

      test('hides cursor when showCursor is false', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(2);
        expect(buffer.textWithCursor(showCursor: false), 'hello');
      });
    });

    group('textWithBlockCursor', () {
      test('splits text around cursor', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(2);
        final result = buffer.textWithBlockCursor();
        expect(result.before, 'he');
        expect(result.cursor, 'l');
        expect(result.after, 'lo');
      });

      test('uses space at end of text', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        final result = buffer.textWithBlockCursor();
        expect(result.before, 'hello');
        expect(result.cursor, ' ');
        expect(result.after, '');
      });
    });

    group('SimpleTextInput extension', () {
      test('append adds to end', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(0);
        buffer.append(' world');
        expect(buffer.text, 'hello world');
      });

      test('removeLast removes from end', () {
        final buffer = TextInputBuffer(initialText: 'hello');
        buffer.setCursorPosition(0);
        buffer.removeLast();
        expect(buffer.text, 'hell');
      });
    });
  });
}

