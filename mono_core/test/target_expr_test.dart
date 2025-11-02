import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  test('TargetExpr types construct', () {
    const all = TargetAll();
    expect(all, isA<TargetExpr>());
    expect(const TargetPackage('core').name, 'core');
    expect(const TargetGroup('apps').groupName, 'apps');
    expect(const TargetGlob('app_*').pattern, 'app_*');
  });
}

