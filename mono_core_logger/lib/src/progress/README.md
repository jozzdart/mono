# progress/

Contracts for representing task progress and grouping.

## Types

- `ProgressHandle`: update fraction/message, emit task-scoped logs, and finish.
- `ProgressTask`: immutable snapshot (id, label, fraction, message, display).
- `ProgressDisplayMode`: `overlay`, `pinnedBelow`, `silent`.
- `ProgressGroupHandle`: nest related tasks and aggregate state.
- `UpdateRateController`: hint to throttle UI updates to avoid flicker.

## Behavior

- Fraction range is 0..1; `null` indicates unknown/indeterminate.
- Implementations may render task logs inline with the task area.
- `finish(success: ...)` signals completion and releases any pinned/overlay area.

## Example (conceptual)

```dart
import 'package:mono_core_logger/mono_core_logger.dart';

void run(Logger logger) {
  final task = logger.startTask('Download', initialFraction: 0.0,
      display: ProgressDisplayMode.pinnedBelow);
  task.update(fraction: 0.6, message: '60%');
  task.log('Chunk 6/10');
  task.finish(success: true, message: 'Complete');
}
```
