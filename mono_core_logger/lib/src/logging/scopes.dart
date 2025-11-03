import 'package:mono_core_logger/mono_core_logger.dart';

/// How logs are captured within a scope for later summarization.
enum CaptureMode {
  /// Do not capture; logs flow to sinks immediately.
  none,

  /// Capture all logs in memory for this scope.
  bufferAll,

  /// Capture only logs that match the active filter.
  bufferFiltered,

  /// Do not buffer full logs; only aggregate counts and severities.
  summaryOnly,
}

/// Policy to silence logs during a scope (for long noisy operations).
enum SilencePolicy {
  /// Do not silence.
  none,

  /// Hide informational/debug/trace; allow warnings and errors.
  importantOnly,

  /// Hide everything except errors.
  errorsOnly,

  /// Hide all log output.
  all,
}

class SummaryReport {
  final int infoCount;
  final int warnCount;
  final int errorCount;
  final List<LogRecord> warnings;
  final List<LogRecord> errors;
  const SummaryReport({
    this.infoCount = 0,
    this.warnCount = 0,
    this.errorCount = 0,
    this.warnings = const <LogRecord>[],
    this.errors = const <LogRecord>[],
  });
}

/// Represents a logging scope with optional filtering/capture/silencing.
abstract class LogScope {
  LogFilter? get filter;
  CaptureMode get capture;
  SilencePolicy get silence;

  /// Close the scope, releasing any resources.
  void close();

  /// Flush buffered content or return final summary.
  SummaryReport flush();
}
