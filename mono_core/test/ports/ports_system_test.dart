import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class FixedClock implements Clock {
  const FixedClock(this.fixedNow);
  final DateTime fixedNow;
  @override
  DateTime now() => fixedNow;
}

class RecordingLogger implements Logger {
  final List<({String message, String? scope, String level})> records = [];
  @override
  void log(String message, {String? scope, String level = 'info'}) {
    records.add((message: message, scope: scope, level: level));
  }
}

class SimplePathService implements PathService {
  @override
  String join(Iterable<String> parts) {
    final nonEmpty = parts.where((p) => p.isNotEmpty).toList();
    return nonEmpty.join('/');
  }

  @override
  String normalize(String path) => path;
}

class FakePlatformInfo implements PlatformInfo {
  const FakePlatformInfo({
    required this.isWindows,
    required this.isLinux,
    required this.isMacOS,
    required this.shell,
  });
  @override
  final bool isWindows;
  @override
  final bool isLinux;
  @override
  final bool isMacOS;
  @override
  final String shell;
}

class StubProcessRunner implements ProcessRunner {
  final List<String> lastCommand = [];
  final List<String?> lastCwd = <String?>[];
  final List<Map<String, String>?> lastEnv = <Map<String, String>?>[];

  @override
  Future<int> run(
    List<String> command, {
    String? cwd,
    Map<String, String>? env,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    lastCommand
      ..clear()
      ..addAll(command);
    lastCwd
      ..clear()
      ..add(cwd);
    lastEnv
      ..clear()
      ..add(env == null ? null : Map<String, String>.from(env));
    onStdout?.call('out-line-1');
    onStderr?.call('err-line-1');
    return 42;
  }
}

void main() {
  group('Clock', () {
    test('returns fixed now()', () {
      final clock = FixedClock(DateTime(2024, 1, 1, 12, 0, 0));
      expect(clock.now(), DateTime(2024, 1, 1, 12, 0, 0));
    });
  });

  group('Logger', () {
    test('defaults level to info and null scope', () {
      final logger = RecordingLogger();
      logger.log('hello');
      expect(logger.records, hasLength(1));
      expect(logger.records.single.message, 'hello');
      expect(logger.records.single.level, 'info');
      expect(logger.records.single.scope, isNull);
    });

    test('accepts custom level and scope', () {
      final logger = RecordingLogger();
      logger.log('warn!', scope: 'build', level: 'warn');
      final r = logger.records.single;
      expect(r.message, 'warn!');
      expect(r.scope, 'build');
      expect(r.level, 'warn');
    });
  });

  group('PathService', () {
    test('join concatenates with forward slash', () {
      final paths = SimplePathService();
      expect(paths.join(['a', 'b', 'c']), 'a/b/c');
      expect(paths.join(['', 'root', 'folder']), 'root/folder');
    });

    test('normalize returns input (stub)', () {
      final paths = SimplePathService();
      expect(paths.normalize('C:/temp/../temp/file.txt'),
          'C:/temp/../temp/file.txt');
    });
  });

  group('PlatformInfo', () {
    test('exposes platform booleans and shell', () {
      const p = FakePlatformInfo(
        isWindows: false,
        isLinux: true,
        isMacOS: false,
        shell: '/bin/bash',
      );
      expect(p.isWindows, isFalse);
      expect(p.isLinux, isTrue);
      expect(p.isMacOS, isFalse);
      expect(p.shell, '/bin/bash');
    });
  });

  group('ProcessRunner', () {
    test('invokes stdout/stderr callbacks and returns exit code', () async {
      final runner = StubProcessRunner();
      final stdoutLines = <String>[];
      final stderrLines = <String>[];

      final code = await runner.run(
        ['echo', 'hi'],
        cwd: '/tmp',
        env: {'A': '1'},
        onStdout: stdoutLines.add,
        onStderr: stderrLines.add,
      );

      expect(code, 42);
      expect(stdoutLines, ['out-line-1']);
      expect(stderrLines, ['err-line-1']);
      expect(runner.lastCommand, ['echo', 'hi']);
      expect(runner.lastCwd.single, '/tmp');
      expect(runner.lastEnv.single, {'A': '1'});
    });
  });
}
