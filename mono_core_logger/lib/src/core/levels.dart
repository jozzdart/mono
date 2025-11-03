enum LogLevel {
  trace,
  debug,
  info,
  success,
  warn,
  error,
  fatal,
}

extension LogLevelPriority on LogLevel {
  int get priority {
    switch (this) {
      case LogLevel.trace:
        return 10;
      case LogLevel.debug:
        return 20;
      case LogLevel.info:
        return 30;
      case LogLevel.success:
        return 35;
      case LogLevel.warn:
        return 40;
      case LogLevel.error:
        return 50;
      case LogLevel.fatal:
        return 60;
    }
  }
}

/// Free-form category hint for routing/formatting.
typedef LogCategory = String;
