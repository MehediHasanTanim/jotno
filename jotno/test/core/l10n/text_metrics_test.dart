import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/l10n/locale_controller.dart';
import 'package:jotno/core/l10n/text_metrics.dart';

void main() {
  group('the line-height rule', () {
    test('body is 15/26 in Bangla and 15/24 in English', () {
      expect(bodyFontSize, 15);
      expect(bodyLineHeightFor(AppLanguage.bangla), 26);
      expect(bodyLineHeightFor(AppLanguage.english), 24);
    });

    test('the style expresses the height as a ratio of the font size', () {
      // `TextStyle.height` is a multiple, so 26/15 is what Flutter needs to
      // be told to produce a 26px line box at 15px type.
      expect(bodyTextStyle(AppLanguage.bangla).fontSize, 15);
      expect(bodyTextStyle(AppLanguage.bangla).height, 26 / 15);
      expect(bodyTextStyle(AppLanguage.english).height, 24 / 15);
    });

    test('Bangla is the taller of the two', () {
      // If this ever inverts, every container sized to the Bangla measure is
      // suddenly sized to the shorter one, and the English build is the one
      // laid out correctly.
      expect(
        bodyLineHeightFor(AppLanguage.bangla),
        greaterThan(bodyLineHeightFor(AppLanguage.english)),
      );
    });

    test('the container measure is the Bangla one, in both languages', () {
      expect(banglaBodyMeasure(1), 26);
      expect(banglaBodyMeasure(3), 78);
    });

    test('the body text theme carries the height at every body size', () {
      final theme = bodyTextTheme(AppLanguage.bangla);

      for (final style in [
        theme.bodyLarge,
        theme.bodyMedium,
        theme.bodySmall,
      ]) {
        expect(style?.height, 26 / 15);
      }
    });
  });

  group('a language switch does not reflow', () {
    testWidgets('a container sized to the Bangla measure holds both', (
      tester,
    ) async {
      // The rule that matters more than the numbers. Bangla text is taller;
      // reserving the Bangla measure means the English build is slightly
      // generous rather than the Bangla build being clipped.
      Future<Size> measure(AppLanguage language, String text) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: language.locale,
            home: Center(
              child: SizedBox(
                width: 200,
                height: banglaBodyMeasure(1),
                child: Text(text, style: bodyTextStyle(language)),
              ),
            ),
          ),
        );
        return tester.getSize(find.byType(SizedBox));
      }

      final banglaSize = await measure(AppLanguage.bangla, 'যত্ন');
      final englishSize = await measure(AppLanguage.english, 'Jotno');

      expect(banglaSize, englishSize);
      expect(banglaSize.height, banglaBodyLineHeight);
    });

    testWidgets('unconstrained Bangla body text is the taller line', (
      tester,
    ) async {
      Future<double> heightOf(AppLanguage language) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: language.locale,
            home: Center(
              child: SizedBox(
                width: 300,
                child: Text('Jotno', style: bodyTextStyle(language)),
              ),
            ),
          ),
        );
        return tester.getSize(find.text('Jotno')).height;
      }

      // Same string in both, so only the metrics differ. This is the reason
      // the container above has to be told a size rather than shrink-wrapping.
      expect(
        await heightOf(AppLanguage.bangla),
        greaterThan(await heightOf(AppLanguage.english)),
      );
    });
  });
}
