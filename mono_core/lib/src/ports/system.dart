import 'package:meta/meta.dart';

@immutable
abstract class Clock {
  const Clock();
  DateTime now();
}

@immutable
abstract class Logger {
  const Logger();
  void log(String message, {String? scope, String level = 'info'});
}

@immutable
abstract class PathService {
  const PathService();
  String join(Iterable<String> parts);
  String normalize(String path);
}

@immutable
abstract class PlatformInfo {
  const PlatformInfo();
  bool get isWindows;
  bool get isLinux;
  bool get isMacOS;
  String get shell;
}

@immutable
abstract class ProcessRunner {
  const ProcessRunner();
  Future<int> run(
    List<String> command, {
    String? cwd,
    Map<String, String>? env,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  });
}
