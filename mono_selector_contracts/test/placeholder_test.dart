import 'package:mono_selector_contracts/mono_selector_contracts.dart';
import 'package:test/test.dart';

void main() {
  test('selector contracts load', () {
    const all = TargetAll();
    expect(all, isA<TargetExpr>());
  });
}

