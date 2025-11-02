import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  test('StdLogger does not throw on info/error logs', () {
    const log = StdLogger();
    expect(() => log.log('hello world', scope: 'test', level: 'info'), returnsNormally);
    expect(() => log.log('boom', level: 'error'), returnsNormally);
  });
}


