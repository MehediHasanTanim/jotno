import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/l10n/locale_controller.dart';
import 'package:jotno/core/l10n/number_format.dart';
import 'package:jotno/l10n/app_localizations.dart';

void main() {
  final bangla = AppNumberFormat.forLanguage(AppLanguage.bangla);
  final english = AppNumberFormat.forLanguage(AppLanguage.english);

  group('Bengali numerals', () {
    test('the matrix case: 124 renders as ১২৪', () {
      expect(bangla.integer(124), '১২৪');
    });

    test('every digit maps', () {
      for (final (index, digit) in '০১২৩৪৫৬৭৮৯'.split('').indexed) {
        expect(bangla.integer(index), digit, reason: 'digit $index');
      }
    });

    test('zero is ০, not an empty string', () {
      expect(bangla.integer(0), '০');
    });

    test('a negative number keeps its sign', () {
      expect(bangla.integer(-7), contains('৭'));
      expect(bangla.integer(-7), isNot(contains('7')));
    });

    test('no Latin digit survives, at any magnitude', () {
      // The rule is absolute: a screen that shows ১২৪ in one row and 124 in
      // the next is an English product with a translation applied.
      final latin = RegExp(r'[0-9]');
      for (final value in <int>[0, 9, 10, 99, 1000, 100000, 12345678]) {
        expect(
          latin.hasMatch(bangla.integer(value)),
          isFalse,
          reason: '$value',
        );
      }
    });
  });

  group('grouping and decimals', () {
    test('Bangla groups in the Indian style, not in thousands', () {
      // 1,23,456 — thousand, then lakh. This is why the formatter wraps
      // `intl` rather than substituting digits into an English-grouped
      // string: the separators land in different places.
      expect(bangla.integer(123456), '১,২৩,৪৫৬');
      expect(english.integer(123456), '123,456');
    });

    test('decimals render with exactly the digits asked for', () {
      expect(bangla.decimal(36.5), '৩৬.৫');
      expect(bangla.decimal(37), '৩৭.০');
      expect(english.decimal(36.5), '36.5');
    });

    test('a two-digit fraction is available for the cases that need it', () {
      expect(english.decimal(1.005, fractionDigits: 2), '1.00');
      expect(bangla.decimal(2.5, fractionDigits: 2), '২.৫০');
    });
  });

  group('English is the ordinary case', () {
    test('124 stays 124', () {
      expect(english.integer(124), '124');
    });
  });

  group('choosing a formatter', () {
    test('an unshipped locale gets Bangla, matching resolveLanguage', () {
      expect(AppNumberFormat.of(const Locale('ar')).integer(5), '৫');
    });

    test('a regional English variant gets English', () {
      expect(AppNumberFormat.of(const Locale('en', 'GB')).integer(5), '5');
    });

    testWidgets('context.numbers follows the locale in force', (tester) async {
      late String rendered;

      Future<void> pumpIn(Locale locale) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: supportedLocales,
            home: Builder(
              builder: (context) {
                rendered = context.numbers.integer(124);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      await pumpIn(const Locale('bn'));
      expect(rendered, '১২৪');

      await pumpIn(const Locale('en'));
      expect(rendered, '124');
    });
  });

  group('tabular figures', () {
    test('the shared feature list is what numeric styles must use', () {
      expect(tabularFigures.single.feature, 'tnum');
      expect(tabularFigures.single.value, 1);
    });
  });
}
