import 'package:mono_core_logger/mono_core_logger.dart';

/// Tag value for grouping/filtering logs.
typedef LogTag = String;

/// Arbitrary structured metadata attached to a log.
typedef LogFields = Map<String, Object?>;

/// Context associated with a stream of logs (e.g., task, scope, correlation).
class LogContext {
  final String? correlationId;
  final String? taskId;
  final String? scopeId;
  final Map<String, Object?> extra;

  const LogContext({
    this.correlationId,
    this.taskId,
    this.scopeId,
    this.extra = const <String, Object?>{},
  });

  LogContext merged(LogContext other) {
    return LogContext(
      correlationId: other.correlationId ?? correlationId,
      taskId: other.taskId ?? taskId,
      scopeId: other.scopeId ?? scopeId,
      extra: {...extra, ...other.extra},
    );
  }
}

/// Immutable structured log record.
class LogRecord {
  final DateTime timestamp;
  final LogLevel level;

  /// Either a plain String or a Renderable (defined in renderables.dart)
  final Object body;
  final List<LogTag> tags;
  final String? category;
  final LogFields fields;
  final LogContext context;

  const LogRecord({
    required this.timestamp,
    required this.level,
    required this.body,
    this.tags = const <LogTag>[],
    this.category,
    this.fields = const <String, Object?>{},
    this.context = const LogContext(),
  });
}
