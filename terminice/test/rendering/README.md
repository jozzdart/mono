# Rendering Test Utilities

This folder contains helpers for testing terminal rendering outputs.

## Quick start

```dart
import 'package:test/test.dart';
import 'package:terminice/src/rendering/src.dart';
import 'test_utils.dart';
import 'matchers.dart';

void main() {
  test('Text prints one line', () {
    final h = RenderHarness();
    final lines = h.renderWidget(Text('hello'));
    expect(lines, printsExactly(['hello']));
  });
}
```

## Helpers

- `RenderHarness.renderWidget(widget, {theme, columns, colorEnabled})` → `List<String>`
- `printsExactly`, `printsContaining`, `printsMatching` matchers
- `RenderNormalize.normalizeLines(lines, strip: true, trimRight: true)`
- `fixedContext(columns: 80, colorEnabled: true, theme: PromptTheme.dark)`

## Notes

- By default, normalization strips ANSI and trims trailing spaces to reduce flakiness.
- For color-sensitive tests, set `stripAnsi: false` in matchers and harness.
- Prefer explicit `columns` to stabilize wrapping and alignment logic.
