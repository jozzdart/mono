import 'progress.dart';
import 'record.dart';

/// Base class for typed logger-related events.
abstract class LoggerEvent {
  const LoggerEvent();
}

class LogRecordEvent extends LoggerEvent {
  final LogRecord record;
  const LogRecordEvent(this.record);
}

class ProgressStartedEvent extends LoggerEvent {
  final ProgressTask task;
  const ProgressStartedEvent(this.task);
}

class ProgressUpdatedEvent extends LoggerEvent {
  final ProgressTask task;
  const ProgressUpdatedEvent(this.task);
}

class ProgressFinishedEvent extends LoggerEvent {
  final String taskId;
  final bool success;
  final String? message;
  const ProgressFinishedEvent(
      {required this.taskId, this.success = true, this.message});
}
