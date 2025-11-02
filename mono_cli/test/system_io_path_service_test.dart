import 'dart:io';

import 'package:mono_cli/mono_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DefaultPathService', () {
    const svc = DefaultPathService();

    test('join combines with platform separator', () {
      final expected = p.joinAll(['a', 'b', 'c']);
      expect(svc.join(['a', 'b', 'c']), expected);
    });

    test('normalize cleans up .. and . segments', () {
      final raw =
          'a${Platform.pathSeparator}.${Platform.pathSeparator}b${Platform.pathSeparator}..${Platform.pathSeparator}c';
      final normalized = svc.normalize(raw);
      // Using path to compute expected across platforms
      expect(normalized, p.normalize(raw));
    });
  });
}
