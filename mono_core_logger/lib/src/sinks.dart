import 'record.dart';

typedef SinkId = String;

/// A sink receives formatted or raw records and performs side effects (e.g., print).
abstract class LogSink {
  SinkId get id;
  void handle(LogRecord record);
  void flush() {}
}

/// Formats a record into an implementation-defined output (string/renderable/or structured).
abstract class LogFormatter {
  Object format(LogRecord record);
}
