import 'package:mono_config_contracts/mono_config_contracts.dart';
import 'package:test/test.dart';

void main() {
  test('config contracts load', () {
    const cfg = MonoConfig(include: ['packages/**'], exclude: []);
    expect(cfg.include.first, 'packages/**');
  });
}

