import 'filters.dart';
import 'record.dart';
import 'sinks.dart';

/// Routes records to sinks, optionally applying filters per-sink.
abstract class LogRouter {
  void addSink(LogSink sink, {LogFilter? filter});
  void removeSink(SinkId id);
  void route(LogRecord record);
}

/// Optional higher-level pipeline interface for plugging formatter and router.
abstract class LogPipeline {
  LogFormatter? get formatter;
  LogRouter get router;
  void process(LogRecord record);
}
