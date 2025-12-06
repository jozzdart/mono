import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

void main() {
  group('SearchableListPrompt', () {
    group('construction', () {
      test('creates with required parameters', () {
        final prompt = SearchableListPrompt<String>(
          title: 'Search',
          items: ['a', 'b', 'c'],
        );

        expect(prompt.title, 'Search');
        expect(prompt.items, ['a', 'b', 'c']);
        expect(prompt.multiSelect, false);
        expect(prompt.maxVisible, 10);
        expect(prompt.searchEnabled, true);
        expect(prompt.theme, PromptTheme.dark);
      });

      test('creates with all parameters', () {
        final prompt = SearchableListPrompt<String>(
          title: 'Custom',
          items: ['x', 'y', 'z'],
          theme: PromptTheme.matrix,
          multiSelect: true,
          maxVisible: 5,
          initialSelection: {0, 2},
          searchEnabled: false,
          showConnector: false,
          hintStyle: HintStyle.grid,
          reservedLines: 10,
        );

        expect(prompt.title, 'Custom');
        expect(prompt.items, ['x', 'y', 'z']);
        expect(prompt.theme, PromptTheme.matrix);
        expect(prompt.multiSelect, true);
        expect(prompt.maxVisible, 5);
        expect(prompt.initialSelection, {0, 2});
        expect(prompt.searchEnabled, false);
        expect(prompt.showConnector, false);
        expect(prompt.hintStyle, HintStyle.grid);
        expect(prompt.reservedLines, 10);
      });

      test('handles empty items', () {
        final prompt = SearchableListPrompt<String>(
          title: 'Empty',
          items: [],
        );

        expect(prompt.items, isEmpty);
      });
    });

    group('wasCancelled', () {
      test('initially false before run', () {
        final prompt = SearchableListPrompt<String>(
          title: 'Test',
          items: ['a'],
        );

        expect(prompt.wasCancelled, false);
      });
    });

    group('static factories', () {
      test('single exists', () {
        expect(SearchableListPrompt.single, isA<Function>());
      });

      test('multi exists', () {
        expect(SearchableListPrompt.multi, isA<Function>());
      });
    });
  });
}

