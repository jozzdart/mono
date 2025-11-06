import 'package:test/test.dart';
import 'test_utils.dart';

Matcher printsExactly(List<String> expected,
    {bool stripAnsi = true, bool trimRight = true}) {
  return _PrintsExactly(expected,
      stripAnsi: stripAnsi, trimRight: trimRight);
}

class _PrintsExactly extends Matcher {
  final List<String> expected;
  final bool stripAnsi;
  final bool trimRight;
  _PrintsExactly(this.expected, {this.stripAnsi = true, this.trimRight = true});

  @override
  Description describe(Description description) =>
      description.add('prints exactly ${expected.length} lines');

  @override
  bool matches(item, Map matchState) {
    if (item is! List<String>) return false;
    final got = RenderNormalize.normalizeLines(item,
        strip: stripAnsi, trimRight: trimRight);
    final want = RenderNormalize.normalizeLines(expected,
        strip: stripAnsi, trimRight: trimRight);
    if (got.length != want.length) {
      matchState['diff'] = 'line count ${got.length} != ${want.length}';
      matchState['got'] = got;
      matchState['want'] = want;
      return false;
    }
    for (int i = 0; i < got.length; i++) {
      if (got[i] != want[i]) {
        matchState['diff'] = 'first diff at line $i';
        matchState['got'] = got[i];
        matchState['want'] = want[i];
        return false;
      }
    }
    return true;
  }

  @override
  Description describeMismatch(item, Description mismatchDescription,
      Map matchState, bool verbose) {
    mismatchDescription
        .add(matchState['diff']?.toString() ?? 'mismatch')
        .add('\n got: ${matchState['got']}\n want: ${matchState['want']}');
    return mismatchDescription;
  }
}

Matcher printsContaining(List<String> snippets) => _PrintsContaining(snippets);

class _PrintsContaining extends Matcher {
  final List<String> snippets;
  _PrintsContaining(this.snippets);

  @override
  Description describe(Description description) =>
      description.add('prints containing snippets in order');

  @override
  bool matches(item, Map matchState) {
    if (item is! List<String>) return false;
    final joined = item.join('\n');
    int pos = 0;
    for (final s in snippets) {
      final idx = joined.indexOf(s, pos);
      if (idx < 0) return false;
      pos = idx + s.length;
    }
    return true;
  }
}

Matcher printsMatching(List<Pattern> patterns) => _PrintsMatching(patterns);

class _PrintsMatching extends Matcher {
  final List<Pattern> patterns;
  _PrintsMatching(this.patterns);

  @override
  Description describe(Description description) =>
      description.add('prints lines matching provided patterns');

  @override
  bool matches(item, Map matchState) {
    if (item is! List<String>) return false;
    if (item.length < patterns.length) return false;
    for (int i = 0; i < patterns.length; i++) {
      final line = item[i];
      final p = patterns[i];
      if (p is RegExp) {
        if (!p.hasMatch(line)) return false;
      } else {
        if (!line.contains(p)) return false;
      }
    }
    return true;
  }
}


