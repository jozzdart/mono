import 'package:test/test.dart';
import 'package:terminice/src/system/focus_navigation.dart';

void main() {
  group('FocusNavigation', () {
    group('construction', () {
      test('creates with valid item count', () {
        final nav = FocusNavigation(itemCount: 5);
        expect(nav.itemCount, 5);
        expect(nav.focusedIndex, 0);
        expect(nav.isNotEmpty, true);
        expect(nav.isEmpty, false);
      });

      test('creates with initial index', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 3);
        expect(nav.focusedIndex, 3);
      });

      test('clamps initial index to valid range', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 10);
        expect(nav.focusedIndex, 4); // clamped to last index

        final nav2 = FocusNavigation(itemCount: 5, initialIndex: -1);
        expect(nav2.focusedIndex, 0); // clamped to first index
      });

      test('handles empty list', () {
        final nav = FocusNavigation(itemCount: 0);
        expect(nav.isEmpty, true);
        expect(nav.isNotEmpty, false);
        expect(nav.focusedIndex, 0);
      });

      test('handles negative item count as zero', () {
        final nav = FocusNavigation(itemCount: -5);
        expect(nav.itemCount, 0);
        expect(nav.isEmpty, true);
      });
    });

    group('navigation', () {
      test('moveBy moves forward with wrapping', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.moveBy(1);
        expect(nav.focusedIndex, 1);
        nav.moveBy(1);
        expect(nav.focusedIndex, 2);
      });

      test('moveBy moves backward with wrapping', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.moveBy(-1);
        expect(nav.focusedIndex, 4); // wraps to last
      });

      test('moveBy wraps at end', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 4);
        nav.moveBy(1);
        expect(nav.focusedIndex, 0);
      });

      test('moveUp and moveDown', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 2);
        nav.moveUp();
        expect(nav.focusedIndex, 1);
        nav.moveDown();
        expect(nav.focusedIndex, 2);
      });

      test('moveNext and movePrevious aliases', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 2);
        nav.movePrevious();
        expect(nav.focusedIndex, 1);
        nav.moveNext();
        expect(nav.focusedIndex, 2);
      });

      test('jumpTo sets specific index', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.jumpTo(3);
        expect(nav.focusedIndex, 3);
      });

      test('jumpTo clamps to valid range', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.jumpTo(10);
        expect(nav.focusedIndex, 4);
        nav.jumpTo(-1);
        expect(nav.focusedIndex, 0);
      });

      test('jumpToFirst and jumpToLast', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 2);
        nav.jumpToLast();
        expect(nav.focusedIndex, 4);
        nav.jumpToFirst();
        expect(nav.focusedIndex, 0);
      });

      test('navigation on empty list is no-op', () {
        final nav = FocusNavigation(itemCount: 0);
        nav.moveBy(1);
        expect(nav.focusedIndex, 0);
        nav.jumpTo(5);
        expect(nav.focusedIndex, 0);
      });

      test('isFocused returns correct state', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 2);
        expect(nav.isFocused(2), true);
        expect(nav.isFocused(0), false);
        expect(nav.isFocused(4), false);
      });

      test('reset restores to initial state', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 3);
        nav.jumpTo(4);
        nav.setError(0, 'Error');
        nav.reset();
        expect(nav.focusedIndex, 0);
        expect(nav.hasAnyError, false);
      });

      test('reset with custom initial index', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.jumpTo(4);
        nav.reset(initialIndex: 2);
        expect(nav.focusedIndex, 2);
      });

      test('reset with clearErrors: false preserves errors', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(0, 'Error');
        nav.reset(clearErrors: false);
        expect(nav.hasAnyError, true);
      });
    });

    group('error tracking', () {
      test('getError returns null initially', () {
        final nav = FocusNavigation(itemCount: 5);
        expect(nav.getError(0), null);
        expect(nav.getError(2), null);
      });

      test('setError and getError', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(2, 'Field is required');
        expect(nav.getError(2), 'Field is required');
        expect(nav.hasError(2), true);
      });

      test('setError with null clears error', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(2, 'Error');
        nav.setError(2, null);
        expect(nav.getError(2), null);
        expect(nav.hasError(2), false);
      });

      test('setError with empty string clears error', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(2, 'Error');
        nav.setError(2, '');
        expect(nav.getError(2), null);
        expect(nav.hasError(2), false);
      });

      test('clearError removes error', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(2, 'Error');
        nav.clearError(2);
        expect(nav.hasError(2), false);
      });

      test('clearAllErrors removes all errors', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(0, 'Error 0');
        nav.setError(2, 'Error 2');
        nav.setError(4, 'Error 4');
        nav.clearAllErrors();
        expect(nav.hasAnyError, false);
      });

      test('hasAnyError and hasNoErrors', () {
        final nav = FocusNavigation(itemCount: 5);
        expect(nav.hasAnyError, false);
        expect(nav.hasNoErrors, true);

        nav.setError(2, 'Error');
        expect(nav.hasAnyError, true);
        expect(nav.hasNoErrors, false);
      });

      test('focusedHasError and focusedError', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 2);
        expect(nav.focusedHasError, false);
        expect(nav.focusedError, null);

        nav.setError(2, 'Error at focused');
        expect(nav.focusedHasError, true);
        expect(nav.focusedError, 'Error at focused');
      });

      test('firstErrorIndex finds first error', () {
        final nav = FocusNavigation(itemCount: 5);
        expect(nav.firstErrorIndex, null);

        nav.setError(2, 'Error 2');
        nav.setError(4, 'Error 4');
        expect(nav.firstErrorIndex, 2);
      });

      test('errorCount returns count of errors', () {
        final nav = FocusNavigation(itemCount: 5);
        expect(nav.errorCount, 0);

        nav.setError(0, 'Error 0');
        nav.setError(2, 'Error 2');
        expect(nav.errorCount, 2);
      });

      test('focusFirstError moves focus to first error', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(2, 'Error 2');
        nav.setError(4, 'Error 4');

        final moved = nav.focusFirstError();
        expect(moved, true);
        expect(nav.focusedIndex, 2);
      });

      test('focusFirstError returns false when no errors', () {
        final nav = FocusNavigation(itemCount: 5);
        final moved = nav.focusFirstError();
        expect(moved, false);
      });

      test('out of bounds error operations are safe', () {
        final nav = FocusNavigation(itemCount: 5);
        // Should not throw
        nav.setError(-1, 'Error');
        nav.setError(10, 'Error');
        expect(nav.getError(-1), null);
        expect(nav.getError(10), null);
        expect(nav.hasError(-1), false);
        expect(nav.hasError(10), false);
      });
    });

    group('item count updates', () {
      test('increasing item count', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.itemCount = 10;
        expect(nav.itemCount, 10);
        expect(nav.focusedIndex, 0); // unchanged
      });

      test('decreasing item count clamps focus', () {
        final nav = FocusNavigation(itemCount: 10, initialIndex: 8);
        nav.itemCount = 5;
        expect(nav.itemCount, 5);
        expect(nav.focusedIndex, 4); // clamped to last valid
      });

      test('decreasing item count removes trailing errors', () {
        final nav = FocusNavigation(itemCount: 5);
        nav.setError(4, 'Error at 4');
        nav.itemCount = 3;
        // Error at index 4 should be gone (index no longer exists)
        expect(nav.hasAnyError, false);
      });

      test('increasing item count adds null errors for new items', () {
        final nav = FocusNavigation(itemCount: 3);
        nav.setError(0, 'Error');
        nav.itemCount = 5;
        expect(nav.getError(0), 'Error');
        expect(nav.getError(3), null);
        expect(nav.getError(4), null);
      });

      test('setting to zero clears everything', () {
        final nav = FocusNavigation(itemCount: 5, initialIndex: 3);
        nav.setError(2, 'Error');
        nav.itemCount = 0;
        expect(nav.isEmpty, true);
        expect(nav.focusedIndex, 0);
      });
    });

    group('validation helpers', () {
      test('validateAll validates all items', () {
        final nav = FocusNavigation(itemCount: 3);
        final values = ['valid', '', 'valid'];

        final allValid = nav.validateAll((index) {
          return values[index].isEmpty ? 'Required' : null;
        });

        expect(allValid, false);
        expect(nav.hasError(0), false);
        expect(nav.hasError(1), true);
        expect(nav.getError(1), 'Required');
        expect(nav.hasError(2), false);
        expect(nav.focusedIndex, 1); // focused first invalid
      });

      test('validateAll with focusFirstInvalid: false', () {
        final nav = FocusNavigation(itemCount: 3);
        final values = ['valid', '', 'valid'];

        nav.validateAll((index) {
          return values[index].isEmpty ? 'Required' : null;
        }, focusFirstInvalid: false);

        expect(nav.focusedIndex, 0); // focus unchanged
      });

      test('validateAll returns true when all valid', () {
        final nav = FocusNavigation(itemCount: 3);
        final values = ['a', 'b', 'c'];

        final allValid = nav.validateAll((index) {
          return values[index].isEmpty ? 'Required' : null;
        });

        expect(allValid, true);
        expect(nav.hasAnyError, false);
      });

      test('validateOne validates single item', () {
        final nav = FocusNavigation(itemCount: 3);

        final valid = nav.validateOne(1, (index) => 'Error at $index');

        expect(valid, false);
        expect(nav.getError(1), 'Error at 1');
        expect(nav.hasError(0), false); // only index 1 validated
      });

      test('validateFocused validates focused item', () {
        final nav = FocusNavigation(itemCount: 3, initialIndex: 2);

        nav.validateFocused((index) => index == 2 ? 'Focused error' : null);

        expect(nav.focusedHasError, true);
        expect(nav.focusedError, 'Focused error');
      });
    });
  });
}

