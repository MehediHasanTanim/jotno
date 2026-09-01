import 'package:flutter_test/flutter_test.dart';

import 'dart_source.dart';

/// Four suites assert things about declarations by reading them back, and all
/// four are only as good as the comment stripping underneath. If a doc comment
/// survived, a key mentioned in prose would satisfy an assertion that no code
/// satisfies — the guard would report coverage it does not have.
void main() {
  group('readPackageCode', () {
    test('strips doc comments before anything is searched', () {
      final code = readPackageCode('lib/core/result/app_failure.dart');

      // These words appear only in the dartdoc of that file.
      expect(code, isNot(contains('SqliteException')));
      expect(code, isNot(contains('obfuscated')));
      // And the declarations themselves are still there.
      expect(code, contains('sealed class AppFailure'));
      expect(code, contains("'failureStorage'"));
    });

    test('fails loudly rather than scanning nothing', () {
      expect(
        () => readPackageCode('lib/core/result/not_a_file.dart'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('freeTextShapesIn', () {
    test('reports which shape matched, not just that one did', () {
      expect(freeTextShapesIn('final String? note;'), [
        'a String field or parameter',
      ]);
      expect(freeTextShapesIn('final Map<String, Object?> extras;'), [
        'a String inside a generic',
      ]);
      expect(freeTextShapesIn('final int count;'), isEmpty);
    });

    test('every declared shape is reachable', () {
      // A shape whose pattern can never match is dead weight that reads as
      // protection.
      const samples = <String, String>{
        'a String field or parameter': 'final String note;',
        'a String inside a generic': 'final List<String> notes;',
        'a dynamic member': 'final dynamic payload;',
        'an Object field': 'final Object? blob;',
      };

      expect(samples.keys.toSet(), freeTextShapes.keys.toSet());
      samples.forEach((shape, sample) {
        expect(
          freeTextShapesIn(sample),
          contains(shape),
          reason: '$shape never matches anything, so it protects nothing',
        );
      });
    });
  });
}
