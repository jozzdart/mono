# renderables/

Structured content for rich CLI output. These are data-only; renderers control
layout, colors, and borders.

## Types

- `Renderable`: base class.
- `ListRenderable`: bullet/numbered lists of strings or nested renderables.
- `TableRenderable`: headers and rows of cells (string or renderable).
- `Section`: titled group with optional collapsed state and body content.
- `KeyValuesRenderable`: key-value pairs.
- `CodeBlockRenderable`: code with optional language hint.
- `DiffRenderable`: lines with `DiffOp` (context/add/remove).
- `TreeRenderable`: a rooted tree of `TreeNode`.

## Composition rules

- Nested renderables are allowed; renderers decide indentation and truncation.
- Keep payloads small; large content should be streamed or paged by impls.

## Example (conceptual)

```dart
import 'package:mono_core_logger/mono_core_logger.dart';

final list = ListRenderable(['one', 'two']);
final table = TableRenderable(headers: ['A', 'B'], rows: [['1', '2']]);
```
