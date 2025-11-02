import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class TestProvider extends CompletionProvider {
  const TestProvider();

  @override
  List<CompletionItem> suggest(CompletionContext context) {
    // Simple demo provider: suggest next token candidates based on last partial
    final prefix = context.line.substring(0, context.cursor);
    final hasTrailingSpace =
        prefix.isNotEmpty && RegExp(r'\s').hasMatch(prefix[prefix.length - 1]);
    final last = hasTrailingSpace
        ? ''
        : (prefix.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).lastOrNull ??
            '');
    final candidates = <String>['run', 'test', 'format', 'list'];
    return candidates
        .where((c) => c.startsWith(last))
        .map((c) => CompletionItem(value: c, description: 'cmd:$c'))
        .toList();
  }
}

extension _LastOrNull<T> on Iterable<T> {
  T? get lastOrNull => this.isEmpty ? null : last;
}

void main() {
  group('CompletionContext', () {
    test('stores line and cursor', () {
      const ctx = CompletionContext(line: 'mono ru', cursor: 7);
      expect(ctx.line, 'mono ru');
      expect(ctx.cursor, 7);
    });
  });

  group('CompletionItem', () {
    test('value-only and with description', () {
      const a = CompletionItem(value: 'run');
      const b = CompletionItem(value: 'run', description: 'execute tasks');
      expect(a.value, 'run');
      expect(a.description, isNull);
      expect(b.description, 'execute tasks');
    });
  });

  group('CompletionProvider', () {
    test('suggest returns candidates filtered by prefix', () {
      const provider = TestProvider();
      final ctx1 = CompletionContext(line: 'mo', cursor: 2);
      final ctx2 = CompletionContext(line: 'run', cursor: 3);
      final ctx3 = CompletionContext(line: 'te', cursor: 2);

      final s1 = provider.suggest(ctx1);
      final s2 = provider.suggest(ctx2);
      final s3 = provider.suggest(ctx3);

      expect(s1, isEmpty); // none start with 'mo'
      expect(s2.map((e) => e.value), ['run']);
      expect(s3.map((e) => e.value), ['test']);
      expect(s2.first.description, 'cmd:run');
    });

    test('handles trailing space (empty last token)', () {
      const provider = TestProvider();
      final ctx = CompletionContext(line: 'mono ', cursor: 5);
      final suggestions = provider.suggest(ctx);
      // With empty last token, all candidates are valid
      expect(suggestions.map((e) => e.value),
          containsAll(['run', 'test', 'format', 'list']));
    });
  });
}
