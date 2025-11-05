import '../lib/src/src.dart';

void main() {
  final editor = TableEditor(
    'Table Editor',
    columns: ['Name', 'Age', 'Role'],
    rows: [
      ['Alice', '29', 'Engineer'],
      ['Bob', '34', 'Designer'],
      ['Charlie', '41', 'Manager'],
    ],
    theme: PromptTheme.pastel,
  );

  final edited = editor.run();

  // Display the result using TableView for a quick preview.
  final preview = TableView(
    'Edited Data',
    columns: ['Name', 'Age', 'Role'],
    rows: edited,
    theme: PromptTheme.pastel,
  );
  preview.run();
}
