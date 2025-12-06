import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

void main() {
  group('SelectableListPrompt', () {
    group('construction', () {
      test('creates with required parameters', () {
        final prompt = SelectableListPrompt<String>(
          title: 'Test',
          items: ['a', 'b', 'c'],
        );

        expect(prompt.title, 'Test');
        expect(prompt.items, ['a', 'b', 'c']);
        expect(prompt.multiSelect, false);
        expect(prompt.maxVisible, 12);
        expect(prompt.theme, PromptTheme.dark);
      });

      test('creates with all parameters', () {
        final prompt = SelectableListPrompt<String>(
          title: 'Custom',
          items: ['x', 'y', 'z'],
          theme: PromptTheme.matrix,
          multiSelect: true,
          maxVisible: 5,
          initialSelection: {0, 2},
          showConnector: false,
          hintStyle: HintStyle.bullets,
          reservedLines: 10,
        );

        expect(prompt.title, 'Custom');
        expect(prompt.items, ['x', 'y', 'z']);
        expect(prompt.theme, PromptTheme.matrix);
        expect(prompt.multiSelect, true);
        expect(prompt.maxVisible, 5);
        expect(prompt.initialSelection, {0, 2});
        expect(prompt.showConnector, false);
        expect(prompt.hintStyle, HintStyle.bullets);
        expect(prompt.reservedLines, 10);
      });

      test('handles empty items', () {
        final prompt = SelectableListPrompt<String>(
          title: 'Empty',
          items: [],
        );

        expect(prompt.items, isEmpty);
      });
    });

    group('builder pattern', () {
      test('creates default builder', () {
        final builder = SelectableListPromptBuilder<String>();
        final prompt = builder
            .title('Built')
            .items(['1', '2', '3'])
            .build();

        expect(prompt.title, 'Built');
        expect(prompt.items, ['1', '2', '3']);
        expect(prompt.multiSelect, false);
      });

      test('creates multiSelect builder', () {
        final prompt = SelectableListPromptBuilder<String>()
            .title('Multi')
            .items(['a', 'b'])
            .multiSelect(true)
            .maxVisible(8)
            .build();

        expect(prompt.title, 'Multi');
        expect(prompt.multiSelect, true);
        expect(prompt.maxVisible, 8);
      });

      test('chains all options', () {
        final prompt = SelectableListPromptBuilder<int>()
            .title('Complete')
            .items([1, 2, 3, 4, 5])
            .theme(PromptTheme.matrix)
            .multiSelect(true)
            .maxVisible(3)
            .initialSelection({1, 3})
            .showConnector(false)
            .hintStyle(HintStyle.inline)
            .reservedLines(5)
            .build();

        expect(prompt.title, 'Complete');
        expect(prompt.items, [1, 2, 3, 4, 5]);
        expect(prompt.theme, PromptTheme.matrix);
        expect(prompt.multiSelect, true);
        expect(prompt.maxVisible, 3);
        expect(prompt.initialSelection, {1, 3});
        expect(prompt.showConnector, false);
        expect(prompt.hintStyle, HintStyle.inline);
        expect(prompt.reservedLines, 5);
      });
    });

    group('wasCancelled', () {
      test('initially false before run', () {
        final prompt = SelectableListPrompt<String>(
          title: 'Test',
          items: ['a'],
        );

        expect(prompt.wasCancelled, false);
      });
    });

    group('static factories', () {
      // Note: These cannot be fully tested without mocking stdin,
      // but we can test the prompt configuration.

      test('single creates non-multiSelect prompt', () {
        // The single() method returns T? directly after running,
        // so we just verify the API signature exists.
        // Full integration tests would require stdin mocking.
        expect(SelectableListPrompt.single, isA<Function>());
      });

      test('multi creates multiSelect prompt', () {
        expect(SelectableListPrompt.multi, isA<Function>());
      });
    });
  });

  group('SelectableListPromptBuilder', () {
    test('default values', () {
      final prompt = SelectableListPromptBuilder<String>()
          .items(['test'])
          .build();

      expect(prompt.title, 'Select'); // default title
      expect(prompt.theme, PromptTheme.dark);
      expect(prompt.multiSelect, false);
      expect(prompt.maxVisible, 12);
      expect(prompt.showConnector, true);
      expect(prompt.hintStyle, HintStyle.grid);
      expect(prompt.reservedLines, 7);
    });
  });
}

