import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultSlugNamePolicy', () {
    const policy = DefaultSlugNamePolicy();

    test('normalize lowers, trims, replaces separators and collapses dashes',
        () {
      expect(policy.normalize('UI Group'), 'ui-group');
      expect(policy.normalize('core_utils'), 'core-utils');
      expect(policy.normalize('  A..B  '), 'a-b');
      expect(policy.normalize('Hello---World'), 'hello-world');
      expect(policy.normalize('spaces   and   tabs'), 'spaces-and-tabs');
      expect(policy.normalize('__Leading__and__trailing__'),
          'leading-and-trailing');
    });

    test('normalize removes non-allowed characters', () {
      expect(policy.normalize('Feat@#1!'), 'feat1');
      expect(policy.normalize('na/me\\test'), 'nametest');
    });

    test('isValid matches allowed pattern', () {
      expect(policy.isValid('ui-group'), isTrue);
      expect(policy.isValid('a'), isTrue);
      expect(policy.isValid('0'), isTrue);
      expect(policy.isValid('-bad'), isFalse);
      expect(policy.isValid('bad-'),
          isTrue); // valid though trailing dash is allowed by regex
      expect(policy.isValid(''), isFalse);
      expect(policy.isValid('UPPER'), isFalse);
      expect(policy.isValid('bad name'), isFalse);
    });
  });
}
