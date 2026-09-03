import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/l10n/locale_controller.dart';
import 'package:jotno/l10n/app_localizations_bn.dart';
import 'package:jotno/l10n/app_localizations_en.dart';
import 'package:jotno/main.dart';

/// The largest dynamic-type setting a reader can choose.
///
/// Both platforms go beyond the ordinary range in their accessibility
/// settings: iOS's largest accessibility size and Android's "largest" font
/// size both land near 3x. Testing at the top of the range rather than at a
/// comfortable 1.3x is the point — the layouts that break are the ones nobody
/// looked at past the default.
const double largestDynamicType = 3;

/// Every `Text` widget currently in the tree.
Iterable<Text> _texts(WidgetTester tester) =>
    tester.widgetList<Text>(find.byType(Text));

/// Asserts that nothing in the tree is configured to cut text off.
///
/// A truncated medication name, member name or condition is a safety defect
/// rather than a cosmetic one: the reader cannot tell that what they are
/// looking at is incomplete. The rule is enforced on the widget's own
/// configuration, so it holds regardless of how much room the test surface
/// happened to give it.
void _expectNothingTruncates(WidgetTester tester, {required String reason}) {
  for (final text in _texts(tester)) {
    expect(
      text.maxLines,
      isNull,
      reason: '$reason: "${text.data}" caps its line count',
    );
    expect(
      text.overflow ?? TextOverflow.clip,
      isNot(anyOf(TextOverflow.ellipsis, TextOverflow.fade)),
      reason: '$reason: "${text.data}" truncates instead of wrapping',
    );
  }
}

void main() {
  final bn = AppLocalizationsBn();
  final en = AppLocalizationsEn();

  /// Renders the rest of the test at [scale] times the ordinary text size.
  ///
  /// Set on the platform dispatcher rather than through an ancestor
  /// `MediaQuery`, because both surfaces build their own `MaterialApp` and
  /// `MediaQuery.fromView` reads the view, not an inherited widget. Wrapping
  /// the app in a `MediaQuery` would be silently ignored and the test would
  /// pass at the default size while claiming to prove something about the
  /// largest one.
  void useTextScale(WidgetTester tester, double scale) {
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  group('the startup error surface at the largest dynamic type', () {
    testWidgets('every reason renders in Bangla without overflowing', (
      tester,
    ) async {
      // A RenderFlex or RenderBox overflow raises a FlutterError, which the
      // test binding captures — `takeException` is how an overflow is
      // detected without inspecting pixels.
      for (final reason in StartupFailure.values) {
        useTextScale(tester, largestDynamicType);
        await tester.pumpWidget(
          DatabaseUnavailableApp(
            reason: reason,
            deviceLocales: const [Locale('bn')],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: '$reason overflowed at ${largestDynamicType}x in Bangla',
        );
        expect(find.text(reason.explain(bn)), findsOneWidget);
      }
    });

    testWidgets('every reason renders in English without overflowing', (
      tester,
    ) async {
      // English is the shorter measure and so the easier case, but the
      // surface is sized to Bangla in both languages: if English overflows,
      // the sizing rule has been broken rather than merely strained.
      for (final reason in StartupFailure.values) {
        useTextScale(tester, largestDynamicType);
        await tester.pumpWidget(
          DatabaseUnavailableApp(
            reason: reason,
            deviceLocales: const [Locale('en')],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: '$reason overflowed at ${largestDynamicType}x in English',
        );
      }
    });

    testWidgets('nothing on the surface truncates at the largest size', (
      tester,
    ) async {
      useTextScale(tester, largestDynamicType);
      await tester.pumpWidget(
        const DatabaseUnavailableApp(
          reason: StartupFailure.missingCipher,
          deviceLocales: [Locale('bn')],
        ),
      );
      await tester.pumpAndSettle();

      _expectNothingTruncates(
        tester,
        reason: 'startup failure surface at ${largestDynamicType}x',
      );
    });

    testWidgets('the message grows taller rather than being clipped', (
      tester,
    ) async {
      // The assertion that proves the scale was actually applied, and that
      // the paragraph answered it by wrapping onto more lines instead of
      // holding its box and cutting glyphs off. A clipped paragraph keeps its
      // height; a wrapping one does not.
      await tester.pumpWidget(
        const DatabaseUnavailableApp(
          reason: StartupFailure.missingCipher,
          deviceLocales: [Locale('bn')],
        ),
      );
      await tester.pumpAndSettle();
      final ordinary = tester
          .getSize(find.text(bn.startupFailureMissingCipher))
          .height;

      // Torn down to an empty tree first. Pumping the identical const widget
      // again would let the framework short-circuit the update, and the second
      // measurement would silently be the first one over again.
      await tester.pumpWidget(const SizedBox.shrink());
      useTextScale(tester, largestDynamicType);
      await tester.pumpWidget(
        const DatabaseUnavailableApp(
          reason: StartupFailure.missingCipher,
          deviceLocales: [Locale('bn')],
        ),
      );
      await tester.pumpAndSettle();
      final enlarged = tester
          .getSize(find.text(bn.startupFailureMissingCipher))
          .height;

      expect(
        enlarged,
        greaterThan(ordinary),
        reason:
            'the paragraph did not grow at ${largestDynamicType}x — either '
            'the text scale was not applied or the text is being clipped',
      );
    });
  });

  group('the app surface at the largest dynamic type', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    testWidgets('renders in Bangla without overflowing', (tester) async {
      useTextScale(tester, largestDynamicType);
      final controller = LocaleController(language: AppLanguage.bangla);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        JotnoApp(database: database, localeController: controller),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(bn.databaseReady('২')), findsOneWidget);
      _expectNothingTruncates(
        tester,
        reason: 'app surface in Bangla at ${largestDynamicType}x',
      );
    });

    testWidgets('survives a language switch at the largest size', (
      tester,
    ) async {
      // The two rules meet here: a switch rebuilds every string, and the
      // container is sized to the Bangla measure so the rebuild does not
      // reflow. At 3x, a layout that only just fitted will not.
      useTextScale(tester, largestDynamicType);
      final controller = LocaleController(
        language: AppLanguage.bangla,
        store: EphemeralLanguageStore(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        JotnoApp(database: database, localeController: controller),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await controller.setLanguage(AppLanguage.english);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(en.databaseReady('2')), findsOneWidget);
      _expectNothingTruncates(
        tester,
        reason: 'app surface in English at ${largestDynamicType}x',
      );
    });
  });

  group('what this file cannot prove', () {
    test('conjunct rendering is a device obligation, not a test one', () {
      // UX-DR23. A widget test lays text out against a test font; it says
      // nothing about whether যুক্তাক্ষর render as conjuncts or fall back to
      // boxes on a real device, and nothing about how TalkBack or VoiceOver
      // pronounce them. Bengali TTS coverage is uneven and that half of the
      // criterion is verified on hardware, per the protocol Story 1.7
      // establishes and every later epic re-runs.
      //
      // This test exists to state the boundary in the suite rather than only
      // in a document, so nobody reads a green run as covering it.
      expect(true, isTrue);
    });
  });
}
