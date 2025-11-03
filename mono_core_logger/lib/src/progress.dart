import 'levels.dart';

/// Hint for how progress should be displayed by an implementation.
enum ProgressDisplayMode {
  /// Transient overlay that updates in place.
  overlay,

  /// Allocate a pinned region below general logs that updates.
  pinnedBelow,

  /// Do not display live progress; may still emit final summary.
  silent,
}

/// Identifier for a pinned display region.
typedef PinnedRegionId = String;

/// Immutable snapshot of a progress task.
class ProgressTask {
  final String id;
  final String label;
  final double? fraction; // 0..1
  final String? message;
  final ProgressDisplayMode display;
  const ProgressTask({
    required this.id,
    required this.label,
    this.fraction,
    this.message,
    this.display = ProgressDisplayMode.overlay,
  });
}

/// Handle returned by the logger to update task progress and logs.
abstract class ProgressHandle {
  String get taskId;
  String get label;

  /// Update progress. Provide only the fields that changed.
  void update({double? fraction, String? message});

  /// Emit a task-scoped log. Implementations may render this within the task area.
  void log(Object message, {LogLevel level = LogLevel.info});

  /// Signal completion. Implementations may render a final line and release resources.
  void finish({bool success = true, String? message});
}
