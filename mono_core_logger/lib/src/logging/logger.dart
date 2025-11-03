import 'package:mono_core_logger/mono_core_logger.dart';

/// High-level logging API.
abstract class Logger {
  void log(
    LogLevel level,
    Object message, {
    List<LogTag> tags = const <LogTag>[],
    LogFields? fields,
    String? category,
  });

  // Convenience shortcuts
  void trace(Object msg,
          {List<LogTag> tags = const <LogTag>[], LogFields? fields}) =>
      log(LogLevel.trace, msg, tags: tags, fields: fields);
  void debug(Object msg,
          {List<LogTag> tags = const <LogTag>[], LogFields? fields}) =>
      log(LogLevel.debug, msg, tags: tags, fields: fields);
  void info(Object msg,
          {List<LogTag> tags = const <LogTag>[], LogFields? fields}) =>
      log(LogLevel.info, msg, tags: tags, fields: fields);
  void success(Object msg,
          {List<LogTag> tags = const <LogTag>[], LogFields? fields}) =>
      log(LogLevel.success, msg, tags: tags, fields: fields);
  void warn(Object msg,
          {List<LogTag> tags = const <LogTag>[], LogFields? fields}) =>
      log(LogLevel.warn, msg, tags: tags, fields: fields);
  void error(Object msg,
          {List<LogTag> tags = const <LogTag>[], LogFields? fields}) =>
      log(LogLevel.error, msg, tags: tags, fields: fields);
  void fatal(Object msg,
          {List<LogTag> tags = const <LogTag>[], LogFields? fields}) =>
      log(LogLevel.fatal, msg, tags: tags, fields: fields);

  // Renderables
  void list(ListRenderable list, {String? title});
  void table(TableRenderable table, {String? title});
  SectionScope section(String title, {bool initiallyCollapsed = false});

  // Progress
  ProgressHandle startTask(
    String label, {
    double? initialFraction, // 0..1
    ProgressDisplayMode display = ProgressDisplayMode.overlay,
    String? taskId,
  });

  // Scopes & silencing
  LogScope scoped({
    LogFilter? filter,
    CaptureMode capture = CaptureMode.none,
    SilencePolicy silence = SilencePolicy.none,
  });
}

/// Section scope for grouping related logs under a titled heading.
abstract class SectionScope {
  void log(Object message, {LogLevel level = LogLevel.info});
  void close();
}

/// Factory for composing child loggers with merged context/category/tags.
abstract class LoggerFactory {
  Logger child({
    String? category,
    List<LogTag> tags = const <LogTag>[],
    LogFields? fields,
    LogContext? context,
  });
}
