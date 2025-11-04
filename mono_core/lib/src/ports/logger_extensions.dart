import 'package:mono_core/mono_core.dart';

extension LogHelpers on Logger {
  void info(String message, {String? scope}) =>
      log(message, scope: scope, level: 'info');

  void warn(String message, {String? scope}) =>
      log(message, scope: scope, level: 'warn');

  void error(String message, {String? scope}) =>
      log(message, scope: scope, level: 'error');

  void success(String message, {String? scope}) =>
      log(message, scope: scope, level: 'success');

  void debug(String message, {String? scope}) =>
      log(message, scope: scope, level: 'debug');

  void header(String message, {String? scope}) =>
      log(message, scope: scope, level: 'header');

  void divider({int width = 40, String char = '─'}) =>
      log(List.filled(width, char).join(), level: 'divider');
}
