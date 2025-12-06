import 'package:test/test.dart';
import 'package:terminice/terminice.dart';

void main() {
  group('SelectableGridPrompt', () {
    group('construction', () {
      test('creates with required parameters', () {
        final prompt = SelectableGridPrompt<String>(
          title: 'Grid',
          items: ['a', 'b', 'c', 'd'],
        );

        expect(prompt.title, 'Grid');
        expect(prompt.items, ['a', 'b', 'c', 'd']);
        expect(prompt.multiSelect, false);
        expect(prompt.columns, 0); // auto
        expect(prompt.theme, PromptTheme.dark);
      });

      test('creates with all parameters', () {
        final prompt = SelectableGridPrompt<String>(
          title: 'Custom',
          items: ['x', 'y', 'z'],
          theme: PromptTheme.matrix,
          multiSelect: true,
          columns: 2,
          cellWidth: 15,
          maxColumns: 4,
          initialSelection: {0, 2},
          hintStyle: HintStyle.bullets,
        );

        expect(prompt.title, 'Custom');
        expect(prompt.items, ['x', 'y', 'z']);
        expect(prompt.theme, PromptTheme.matrix);
        expect(prompt.multiSelect, true);
        expect(prompt.columns, 2);
        expect(prompt.cellWidth, 15);
        expect(prompt.maxColumns, 4);
        expect(prompt.initialSelection, {0, 2});
        expect(prompt.hintStyle, HintStyle.bullets);
      });

      test('handles empty items', () {
        final prompt = SelectableGridPrompt<String>(
          title: 'Empty',
          items: [],
        );

        expect(prompt.items, isEmpty);
      });
    });

    group('responsive factory', () {
      test('creates responsive grid', () {
        final prompt = SelectableGridPrompt<String>.responsive(
          title: 'Responsive',
          items: ['a', 'b', 'c'],
          cellWidth: 20,
        );

        expect(prompt.title, 'Responsive');
        expect(prompt.columns, 0); // auto
        expect(prompt.cellWidth, 20);
      });

      test('responsive with maxColumns', () {
        final prompt = SelectableGridPrompt<String>.responsive(
          title: 'Capped',
          items: ['a', 'b', 'c', 'd', 'e'],
          cellWidth: 15,
          maxColumns: 3,
        );

        expect(prompt.maxColumns, 3);
      });
    });

    group('wasCancelled', () {
      test('initially false before run', () {
        final prompt = SelectableGridPrompt<String>(
          title: 'Test',
          items: ['a'],
        );

        expect(prompt.wasCancelled, false);
      });
    });

    group('static factories', () {
      test('single exists', () {
        expect(SelectableGridPrompt.single, isA<Function>());
      });

      test('multi exists', () {
        expect(SelectableGridPrompt.multi, isA<Function>());
      });
    });
  });
}

