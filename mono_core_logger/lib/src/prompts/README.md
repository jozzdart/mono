# prompts/

Contracts for interactive prompts with a strict separation of concerns:
model (state + events), session (lifecycle), renderer (view), and key mapping.

## Components

- `PromptDriver`: high-level convenience (confirm/select/input), no IO here.
- `PromptModel<TState>`: exposes `state`, `events`, and completion status.
- `PromptSession<T>`: owns a model, exposes a `result` future, accepts logical
  `PromptInput` events (`MoveUp/Down`, `Toggle`, `Submit`, etc.).
- `PromptRenderer`: observes a model and draws it into a `RegionId` (hint only).
- `PromptKeyMap`: maps device keys (e.g., `KeyDescriptor`) to `PromptInput`.

## Selection models

- `SelectPromptModel<T>`: single selection via `highlightedIndex`.
- `MultiSelectPromptModel<T>`: multiple selections via `Set<int>` and
  `SelectionConstraints` (min/max).
- `ChecklistOption<T>`: value, label, optional `disabled`, `hint`.

## Example (conceptual)

```dart
import 'package:mono_core_logger/mono_core_logger.dart';

Future<void> flow(PromptDriver prompts) async {
  final agreed = await prompts.confirm('Proceed?', initialValue: false);
  if (!agreed) return;
  final choice = await prompts.select('Pick one', ['A', 'B', 'C']);
  final name = await prompts.input('Your name:');
}
```

## Implementation guidance

- Keep models pure and deterministic; renderers are free to style/layout.
- Renderers should respect `RegionId` hints and avoid interfering with logs.
- Provide accessible key bindings and a clear submit/cancel path.
