import 'package:mono_core_types/mono_core_types.dart';
import 'package:test/test.dart';

void main() {
  test('package loads', () {
    expect(const PackageName('a').toString(), 'a');
  });
}

