import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  test('SystemClock.now returns reasonable current time', () async {
    const clock = SystemClock();
    final before = DateTime.now();
    final now = clock.now();
    final after = DateTime.now();
    expect(now.isAfter(before) || now.isAtSameMomentAs(before), isTrue);
    expect(now.isBefore(after) || now.isAtSameMomentAs(after), isTrue);
  });
}


