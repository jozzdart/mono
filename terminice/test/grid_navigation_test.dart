import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

void main() {
  group('GridNavigation', () {
    group('initialization', () {
      test('creates grid with correct dimensions', () {
        final grid = GridNavigation(itemCount: 12, columns: 4);
        expect(grid.itemCount, equals(12));
        expect(grid.columns, equals(4));
        expect(grid.rows, equals(3));
        expect(grid.focusedIndex, equals(0));
      });

      test('handles empty grid', () {
        final grid = GridNavigation(itemCount: 0, columns: 3);
        expect(grid.isEmpty, isTrue);
        expect(grid.rows, equals(0));
      });

      test('clamps initial index to valid range', () {
        final grid = GridNavigation(itemCount: 5, columns: 3, initialIndex: 10);
        expect(grid.focusedIndex, equals(4));
      });

      test('handles single item', () {
        final grid = GridNavigation(itemCount: 1, columns: 3);
        expect(grid.rows, equals(1));
        expect(grid.focusedIndex, equals(0));
      });
    });

    group('horizontal navigation', () {
      test('moveRight increments index', () {
        final grid = GridNavigation(itemCount: 9, columns: 3);
        grid.moveRight();
        expect(grid.focusedIndex, equals(1));
        grid.moveRight();
        expect(grid.focusedIndex, equals(2));
      });

      test('moveRight wraps at end', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 8);
        grid.moveRight();
        expect(grid.focusedIndex, equals(0));
      });

      test('moveLeft decrements index', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 2);
        grid.moveLeft();
        expect(grid.focusedIndex, equals(1));
      });

      test('moveLeft wraps at start', () {
        final grid = GridNavigation(itemCount: 9, columns: 3);
        grid.moveLeft();
        expect(grid.focusedIndex, equals(8));
      });
    });

    group('vertical navigation', () {
      test('moveDown moves to next row same column', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 1);
        grid.moveDown();
        expect(grid.focusedIndex, equals(4)); // column 1, row 1
      });

      test('moveDown wraps to top', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 7);
        grid.moveDown();
        expect(grid.focusedIndex, equals(1)); // column 1, row 0
      });

      test('moveUp moves to previous row same column', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 4);
        grid.moveUp();
        expect(grid.focusedIndex, equals(1)); // column 1, row 0
      });

      test('moveUp wraps to bottom', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 1);
        grid.moveUp();
        expect(grid.focusedIndex, equals(7)); // column 1, row 2
      });

      test('moveDown handles incomplete last row', () {
        // 8 items in 3 columns = rows: [0,1,2], [3,4,5], [6,7,_]
        final grid = GridNavigation(itemCount: 8, columns: 3, initialIndex: 2);
        // Column 2 doesn't exist in last row, should wrap to column 2 in first row
        grid.moveDown();
        expect(grid.focusedIndex, equals(5)); // row 1, column 2
        grid.moveDown();
        // Now at row 1, column 2 (index 5), going down should go to row 0
        expect(grid.focusedColumn, equals(2));
      });

      test('moveUp handles incomplete last row', () {
        // 8 items in 3 columns
        final grid = GridNavigation(itemCount: 8, columns: 3, initialIndex: 2);
        // From column 2, row 0, move up should go to row 1 column 2 (last valid in that column)
        grid.moveUp();
        expect(grid.focusedIndex, equals(5)); // row 1, column 2
      });
    });

    group('jump operations', () {
      test('jumpTo moves to specific index', () {
        final grid = GridNavigation(itemCount: 9, columns: 3);
        grid.jumpTo(5);
        expect(grid.focusedIndex, equals(5));
      });

      test('jumpTo clamps to valid range', () {
        final grid = GridNavigation(itemCount: 9, columns: 3);
        grid.jumpTo(20);
        expect(grid.focusedIndex, equals(8));
        grid.jumpTo(-5);
        expect(grid.focusedIndex, equals(0));
      });

      test('jumpToCell moves to row/column', () {
        final grid = GridNavigation(itemCount: 9, columns: 3);
        grid.jumpToCell(1, 2);
        expect(grid.focusedIndex, equals(5)); // row 1, column 2
        expect(grid.focusedRow, equals(1));
        expect(grid.focusedColumn, equals(2));
      });

      test('jumpToFirst and jumpToLast', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 4);
        grid.jumpToFirst();
        expect(grid.focusedIndex, equals(0));
        grid.jumpToLast();
        expect(grid.focusedIndex, equals(8));
      });
    });

    group('layout queries', () {
      test('focusedRow and focusedColumn', () {
        final grid = GridNavigation(itemCount: 12, columns: 4, initialIndex: 7);
        expect(grid.focusedRow, equals(1));
        expect(grid.focusedColumn, equals(3));
      });

      test('isFocused returns correct result', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 4);
        expect(grid.isFocused(4), isTrue);
        expect(grid.isFocused(3), isFalse);
        expect(grid.isFocused(5), isFalse);
      });

      test('layout getter returns correct info', () {
        final grid = GridNavigation(itemCount: 10, columns: 3, initialIndex: 7);
        final layout = grid.layout;
        expect(layout.itemCount, equals(10));
        expect(layout.columns, equals(3));
        expect(layout.rows, equals(4));
        expect(layout.focusedIndex, equals(7));
        expect(layout.focusedRow, equals(2));
        expect(layout.focusedColumn, equals(1));
      });
    });

    group('dynamic updates', () {
      test('itemCount setter clamps focus', () {
        final grid = GridNavigation(itemCount: 10, columns: 3, initialIndex: 8);
        grid.itemCount = 5;
        expect(grid.focusedIndex, equals(4));
      });

      test('itemCount setter to zero', () {
        final grid = GridNavigation(itemCount: 10, columns: 3, initialIndex: 5);
        grid.itemCount = 0;
        expect(grid.isEmpty, isTrue);
        expect(grid.focusedIndex, equals(0));
      });

      test('columns setter updates layout', () {
        final grid = GridNavigation(itemCount: 12, columns: 3);
        expect(grid.rows, equals(4));
        grid.columns = 4;
        expect(grid.rows, equals(3));
        expect(grid.columns, equals(4));
      });

      test('reset restores initial state', () {
        final grid = GridNavigation(itemCount: 9, columns: 3, initialIndex: 5);
        grid.moveRight();
        grid.moveDown();
        grid.reset();
        expect(grid.focusedIndex, equals(0));
      });

      test('reset with custom initial index', () {
        final grid = GridNavigation(itemCount: 9, columns: 3);
        grid.reset(initialIndex: 4);
        expect(grid.focusedIndex, equals(4));
      });
    });

    group('rowsOf', () {
      test('iterates rows correctly', () {
        final items = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
        final grid = GridNavigation(itemCount: items.length, columns: 3);

        final rowsList = grid.rowsOf(items).toList();
        expect(rowsList.length, equals(3));

        expect(rowsList[0].row, equals(0));
        expect(rowsList[0].items, equals(['a', 'b', 'c']));
        expect(rowsList[0].startIndex, equals(0));
        expect(rowsList[0].isLastRow, isFalse);

        expect(rowsList[1].row, equals(1));
        expect(rowsList[1].items, equals(['d', 'e', 'f']));
        expect(rowsList[1].startIndex, equals(3));
        expect(rowsList[1].isLastRow, isFalse);

        expect(rowsList[2].row, equals(2));
        expect(rowsList[2].items, equals(['g']));
        expect(rowsList[2].startIndex, equals(6));
        expect(rowsList[2].isLastRow, isTrue);
      });
    });

    group('factory constructors', () {
      test('responsive calculates columns from width', () {
        final grid = GridNavigation.responsive(
          itemCount: 20,
          cellWidth: 10,
          availableWidth: 50,
          separatorWidth: 1,
          prefixWidth: 2,
        );
        // (50 - 2 + 1) / (10 + 1) = 49 / 11 = 4
        expect(grid.columns, equals(4));
      });

      test('responsive respects maxColumns', () {
        final grid = GridNavigation.responsive(
          itemCount: 20,
          cellWidth: 10,
          availableWidth: 100,
          maxColumns: 3,
        );
        expect(grid.columns, equals(3));
      });

      test('balanced creates roughly square grid', () {
        final grid = GridNavigation.balanced(itemCount: 16);
        // sqrt(16) = 4
        expect(grid.columns, equals(4));
        expect(grid.rows, equals(4));
      });

      test('balanced with constraints', () {
        final grid = GridNavigation.balanced(
          itemCount: 16,
          maxColumns: 3,
        );
        expect(grid.columns, equals(3));
      });
    });
  });
}

