import 'package:test/test.dart';
import 'package:terminice/src/system/list_navigation.dart';

void main() {
  group('ListNavigation', () {
    group('construction', () {
      test('initializes with correct defaults', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        expect(nav.selectedIndex, 0);
        expect(nav.scrollOffset, 0);
        expect(nav.itemCount, 10);
        expect(nav.maxVisible, 5);
      });

      test('clamps initial index to valid range', () {
        final nav = ListNavigation(
          itemCount: 5,
          maxVisible: 3,
          initialIndex: 100,
        );
        expect(nav.selectedIndex, 4); // Clamped to last index
      });

      test('handles empty list', () {
        final nav = ListNavigation(itemCount: 0, maxVisible: 5);
        expect(nav.isEmpty, true);
        expect(nav.isNotEmpty, false);
        expect(nav.selectedIndex, 0);
        expect(nav.scrollOffset, 0);
      });
    });

    group('navigation', () {
      test('moveDown wraps at end', () {
        final nav = ListNavigation(itemCount: 3, maxVisible: 10);
        nav.jumpTo(2); // Last item
        nav.moveDown();
        expect(nav.selectedIndex, 0); // Wrapped to first
      });

      test('moveUp wraps at start', () {
        final nav = ListNavigation(itemCount: 3, maxVisible: 10);
        nav.moveUp(); // From index 0
        expect(nav.selectedIndex, 2); // Wrapped to last
      });

      test('moveBy moves multiple positions', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        nav.moveBy(5);
        expect(nav.selectedIndex, 5);
      });

      test('jumpTo sets exact position', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        nav.jumpTo(7);
        expect(nav.selectedIndex, 7);
      });

      test('jumpToFirst goes to index 0', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        nav.jumpTo(5);
        nav.jumpToFirst();
        expect(nav.selectedIndex, 0);
      });

      test('jumpToLast goes to last index', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        nav.jumpToLast();
        expect(nav.selectedIndex, 9);
      });
    });

    group('scrolling', () {
      test('scroll adjusts when selection moves below viewport', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 3);
        nav.moveBy(4); // Move beyond viewport
        expect(nav.selectedIndex, 4);
        expect(nav.scrollOffset, 2); // Adjusted to keep selection visible
      });

      test('scroll adjusts when selection moves above viewport', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 3);
        nav.jumpTo(5);
        nav.moveBy(-3); // Move above current viewport
        expect(nav.selectedIndex, 2);
        expect(nav.scrollOffset, 2); // Viewport follows selection
      });

      test('hasOverflowAbove and hasOverflowBelow are correct', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 3);

        // At start
        expect(nav.hasOverflowAbove, false);
        expect(nav.hasOverflowBelow, true);

        // In middle
        nav.jumpTo(5);
        expect(nav.hasOverflowAbove, true);
        expect(nav.hasOverflowBelow, true);

        // At end
        nav.jumpToLast();
        expect(nav.hasOverflowAbove, true);
        expect(nav.hasOverflowBelow, false);
      });
    });

    group('viewport', () {
      test('returns correct viewport boundaries', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 3);
        nav.jumpTo(5);

        final vp = nav.viewport;
        expect(vp.start, 3);
        expect(vp.end, 6);
        expect(vp.length, 3);
        expect(vp.hasOverflowAbove, true);
        expect(vp.hasOverflowBelow, true);
      });

      test('isSelected returns correct value', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 3);
        nav.jumpTo(5);

        expect(nav.isSelected(5), true);
        expect(nav.isSelected(4), false);
        expect(nav.isSelected(6), false);
      });
    });

    group('visibleWindow', () {
      test('returns correct window of items', () {
        final items = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
        final nav = ListNavigation(itemCount: items.length, maxVisible: 3);
        nav.jumpTo(5);

        final window = nav.visibleWindow(items);
        expect(window.items, ['d', 'e', 'f']);
        expect(window.start, 3);
        expect(window.end, 6);
        expect(window.hasOverflowAbove, true);
        expect(window.hasOverflowBelow, true);
      });

      test('handles empty list', () {
        final nav = ListNavigation(itemCount: 0, maxVisible: 3);
        final window = nav.visibleWindow<String>([]);

        expect(window.isEmpty, true);
        expect(window.hasOverflowAbove, false);
        expect(window.hasOverflowBelow, false);
      });
    });

    group('dynamic updates', () {
      test('itemCount update clamps selection', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        nav.jumpTo(8);
        nav.itemCount = 5; // Reduce count
        expect(nav.selectedIndex, 4); // Clamped to new last index
      });

      test('maxVisible update adjusts scroll', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 3);
        nav.jumpTo(5);
        expect(nav.scrollOffset, 3);

        nav.maxVisible = 5;
        // Scroll should adjust to keep selection visible
        expect(nav.scrollOffset <= nav.selectedIndex, true);
      });

      test('reset goes back to initial state', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        nav.jumpTo(7);
        nav.reset();
        expect(nav.selectedIndex, 0);
        expect(nav.scrollOffset, 0);
      });

      test('reset with initialIndex goes to specified position', () {
        final nav = ListNavigation(itemCount: 10, maxVisible: 5);
        nav.jumpTo(7);
        nav.reset(initialIndex: 3);
        expect(nav.selectedIndex, 3);
      });
    });
  });
}


