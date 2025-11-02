import 'package:mono_cli_shared_contracts/mono_cli_shared_contracts.dart';
import 'package:test/test.dart';

void main() {
  test('cli contracts load', () {
    const tree = CliCommandTree(root: CliCommand(name: 'mono'));
    expect(tree.root.name, 'mono');
  });
}

