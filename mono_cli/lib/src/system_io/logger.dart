import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

class StdLogger implements Logger {
  const StdLogger();

  @override
  void log(String message, {String? scope, String level = 'info'}) {
    final prefix = scope != null ? '[$scope]' : '';
    final line =
        '${DateTime.now().toIso8601String()} [$level] $prefix $message';
    if (level == 'error') {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }
}
