import 'package:test/test.dart';
import 'package:mono_core/src/types/errors.dart';

void main() {
  group('MonoError', () {
    test('toString returns message', () {
      final error = ValidationError('validation failed');
      expect(error.toString(), 'validation failed');
    });
  });

  group('ValidationError', () {
    test('is a MonoError and preserves message', () {
      final e = ValidationError('bad input');
      expect(e, isA<MonoError>());
      expect(e.message, 'bad input');
      expect(e.toString(), 'bad input');
    });
  });

  group('SelectionError', () {
    test('is a MonoError and preserves message', () {
      final e = SelectionError('no match');
      expect(e, isA<MonoError>());
      expect(e.message, 'no match');
      expect(e.toString(), 'no match');
    });
  });

  group('GraphCycleError', () {
    test('is a MonoError and preserves message with null cycle', () {
      final e = GraphCycleError('cycle detected');
      expect(e, isA<MonoError>());
      expect(e.message, 'cycle detected');
      expect(e.cycle, isNull);
      expect(e.toString(), 'cycle detected');
    });

    test('preserves provided non-empty cycle and message', () {
      final e = GraphCycleError(
        'cycle detected',
        cycle: const ['a', 'b', 'c', 'a'],
      );
      expect(e.cycle, isNotNull);
      expect(e.cycle, ['a', 'b', 'c', 'a']);
      expect(e.toString(), 'cycle detected');
    });
  });
}


