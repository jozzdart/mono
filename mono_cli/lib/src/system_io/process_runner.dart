import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mono_core/mono_core.dart';

class DefaultProcessRunner implements ProcessRunner {
  const DefaultProcessRunner();

  @override
  Future<int> run(
    List<String> command, {
    String? cwd,
    Map<String, String>? env,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    final process = await Process.start(
      command.first,
      command.skip(1).toList(),
      workingDirectory: cwd,
      environment: env,
      runInShell: false,
    );

    final outLines =
        process.stdout.transform(utf8.decoder).transform(const LineSplitter());
    final errLines =
        process.stderr.transform(utf8.decoder).transform(const LineSplitter());
    final subs = <StreamSubscription>[];
    if (onStdout != null) {
      subs.add(outLines.listen(onStdout));
    } else {
      subs.add(outLines.listen((l) => stdout.writeln(l)));
    }
    if (onStderr != null) {
      subs.add(errLines.listen(onStderr));
    } else {
      subs.add(errLines.listen((l) => stderr.writeln(l)));
    }

    final code = await process.exitCode;
    for (final s in subs) {
      await s.cancel();
    }
    return code;
  }
}
