import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

void main() {
  group('SelectionController', () {
    group('single-select mode', () {
      test('starts empty', () {
        final sel = SelectionController.single();
        expect(sel.isEmpty, isTrue);
        expect(sel.isNotEmpty, isFalse);
        expect(sel.count, equals(0));
        expect(sel.selectedIndex, isNull);
      });

      test('toggle selects an item', () {
        final sel = SelectionController.single();
        sel.toggle(2);
        expect(sel.isSelected(2), isTrue);
        expect(sel.count, equals(1));
        expect(sel.selectedIndex, equals(2));
      });

      test('toggle replaces previous selection', () {
        final sel = SelectionController.single();
        sel.toggle(2);
        sel.toggle(5);
        expect(sel.isSelected(2), isFalse);
        expect(sel.isSelected(5), isTrue);
        expect(sel.count, equals(1));
      });

      test('select replaces previous selection', () {
        final sel = SelectionController.single();
        sel.select(2);
        sel.select(5);
        expect(sel.isSelected(2), isFalse);
        expect(sel.isSelected(5), isTrue);
      });

      test('deselect removes selection', () {
        final sel = SelectionController.single();
        sel.select(3);
        sel.deselect(3);
        expect(sel.isEmpty, isTrue);
      });

      test('clear removes all selections', () {
        final sel = SelectionController.single();
        sel.select(3);
        sel.clear();
        expect(sel.isEmpty, isTrue);
      });

      test('getSelected returns selected item', () {
        final items = ['a', 'b', 'c', 'd'];
        final sel = SelectionController.single();
        sel.select(2);
        expect(sel.getSelected(items), equals('c'));
      });

      test('getSelected uses fallback when nothing selected', () {
        final items = ['a', 'b', 'c', 'd'];
        final sel = SelectionController.single();
        expect(sel.getSelected(items, fallbackIndex: 1), equals('b'));
      });

      test('selectAll is ignored in single-select mode', () {
        final sel = SelectionController.single();
        sel.selectAll(5);
        expect(sel.isEmpty, isTrue);
      });

      test('initial selection works', () {
        final sel = SelectionController.single(initialIndex: 3);
        expect(sel.isSelected(3), isTrue);
        expect(sel.count, equals(1));
      });
    });

    group('multi-select mode', () {
      test('starts empty', () {
        final sel = SelectionController.multi();
        expect(sel.isEmpty, isTrue);
        expect(sel.multiSelect, isTrue);
      });

      test('toggle adds items', () {
        final sel = SelectionController.multi();
        sel.toggle(1);
        sel.toggle(3);
        sel.toggle(5);
        expect(sel.count, equals(3));
        expect(sel.isSelected(1), isTrue);
        expect(sel.isSelected(3), isTrue);
        expect(sel.isSelected(5), isTrue);
      });

      test('toggle removes if already selected', () {
        final sel = SelectionController.multi();
        sel.toggle(1);
        sel.toggle(3);
        sel.toggle(1); // Remove
        expect(sel.count, equals(1));
        expect(sel.isSelected(1), isFalse);
        expect(sel.isSelected(3), isTrue);
      });

      test('selectAll selects all indices', () {
        final sel = SelectionController.multi();
        sel.selectAll(5);
        expect(sel.count, equals(5));
        for (var i = 0; i < 5; i++) {
          expect(sel.isSelected(i), isTrue);
        }
      });

      test('toggleAll selects all when some unselected', () {
        final sel = SelectionController.multi();
        sel.select(1);
        sel.select(3);
        sel.toggleAll(5);
        expect(sel.count, equals(5));
      });

      test('toggleAll clears when all selected', () {
        final sel = SelectionController.multi();
        sel.selectAll(5);
        sel.toggleAll(5);
        expect(sel.isEmpty, isTrue);
      });

      test('invert swaps selection', () {
        final sel = SelectionController.multi();
        sel.select(0);
        sel.select(2);
        sel.invert(4);
        expect(sel.isSelected(0), isFalse);
        expect(sel.isSelected(1), isTrue);
        expect(sel.isSelected(2), isFalse);
        expect(sel.isSelected(3), isTrue);
      });

      test('getSelectedMany returns selected items in order', () {
        final items = ['a', 'b', 'c', 'd', 'e'];
        final sel = SelectionController.multi();
        sel.select(3);
        sel.select(1);
        sel.select(4);
        final result = sel.getSelectedMany(items);
        expect(result, equals(['b', 'd', 'e'])); // sorted by index
      });

      test('getSelectedMany uses fallback when empty', () {
        final items = ['a', 'b', 'c'];
        final sel = SelectionController.multi();
        final result = sel.getSelectedMany(items, fallbackIndex: 1);
        expect(result, equals(['b']));
      });

      test('getSelectedIndices returns sorted indices', () {
        final sel = SelectionController.multi();
        sel.select(5);
        sel.select(2);
        sel.select(8);
        expect(sel.getSelectedIndices(), equals([2, 5, 8]));
      });

      test('initial selection works', () {
        final sel = SelectionController.multi(initialSelection: {1, 3, 5});
        expect(sel.count, equals(3));
        expect(sel.isSelected(1), isTrue);
        expect(sel.isSelected(3), isTrue);
        expect(sel.isSelected(5), isTrue);
      });
    });

    group('constrainTo', () {
      test('removes out-of-bounds indices', () {
        final sel = SelectionController.multi();
        sel.selectAll(10);
        sel.constrainTo(5);
        expect(sel.count, equals(5));
        expect(sel.isSelected(4), isTrue);
        expect(sel.isSelected(5), isFalse);
      });

      test('does nothing when all in bounds', () {
        final sel = SelectionController.multi();
        sel.select(1);
        sel.select(3);
        sel.constrainTo(10);
        expect(sel.count, equals(2));
      });
    });

    group('summary', () {
      test('returns none selected when empty', () {
        final sel = SelectionController.multi();
        expect(sel.summary(5), equals('none selected'));
      });

      test('returns count when items selected', () {
        final sel = SelectionController.multi();
        sel.select(1);
        sel.select(3);
        expect(sel.summary(10), equals('2/10 selected'));
      });
    });

    group('copy', () {
      test('creates independent copy', () {
        final sel = SelectionController.multi();
        sel.select(1);
        sel.select(3);
        final copy = sel.copy();

        copy.select(5);
        copy.deselect(1);

        expect(sel.isSelected(1), isTrue);
        expect(sel.isSelected(5), isFalse);
        expect(copy.isSelected(1), isFalse);
        expect(copy.isSelected(5), isTrue);
      });
    });

    group('selectedIndices', () {
      test('returns unmodifiable set', () {
        final sel = SelectionController.multi();
        sel.select(1);
        final indices = sel.selectedIndices;
        expect(() => (indices).add(5), throwsA(anything));
      });
    });
  });
}
