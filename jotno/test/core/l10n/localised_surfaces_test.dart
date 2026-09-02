import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/l10n/failure_messages.dart';
import 'package:jotno/core/l10n/locale_controller.dart';
import 'package:jotno/core/result/app_failure.dart';
import 'package:jotno/l10n/app_localizations_bn.dart';
import 'package:jotno/l10n/app_localizations_en.dart';
import 'package:jotno/main.dart';

/// Every `Text` the tree currently renders, joined.
String _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .join('\n');

Map<String, Object?> _arb(String name) =>
    (jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map)
        .cast<String, Object?>();

void main() {
  final bn = AppLocalizationsBn();
  final en = AppLocalizationsEn();

  group('the startup error surface localises without the database', () {
    // The case the whole design turns on. This surface renders precisely when
    // the database will not open, so there is no stored choice to read — it
    // resolves from the device locale, and it must not itself throw.

    testWidgets('an Arabic device sees Bangla, not English', (tester) async {
      await tester.pumpWidget(
        const DatabaseUnavailableApp(
          reason: StartupFailure.missingCipher,
          deviceLocales: [Locale('ar')],
        ),
      );

      expect(find.text(bn.startupFailureTitle), findsOneWidget);
      expect(find.text(bn.startupFailureMissingCipher), findsOneWidget);
    });

    testWidgets('an English device sees English', (tester) async {
      await tester.pumpWidget(
        const DatabaseUnavailableApp(
          reason: StartupFailure.missingCipher,
          deviceLocales: [Locale('en', 'US')],
        ),
      );

      expect(find.text(en.startupFailureTitle), findsOneWidget);
      expect(find.text(en.startupFailureMissingCipher), findsOneWidget);
    });

    testWidgets('every reason renders in Bangla without throwing', (
      tester,
    ) async {
      for (final reason in StartupFailure.values) {
        await tester.pumpWidget(
          DatabaseUnavailableApp(
            reason: reason,
            deviceLocales: const [Locale('bn')],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: '$reason');

        final texts = _renderedText(tester);
        expect(texts, contains(bn.startupFailureTitle));
        expect(texts, contains(reason.explain(bn)));
        // Still true after localisation: nothing derived from an exception
        // reaches this screen.
        expect(texts, isNot(contains('SqliteException')));
        expect(texts, isNot(contains('pragma')));
      }
    });

    testWidgets('no reason renders an empty message, in either language', (
      tester,
    ) async {
      for (final reason in StartupFailure.values) {
        expect(reason.explain(bn).trim(), isNotEmpty, reason: '$reason bn');
        expect(reason.explain(en).trim(), isNotEmpty, reason: '$reason en');
        expect(
          reason.explain(bn),
          isNot(reason.explain(en)),
          reason: '$reason was never translated',
        );
      }
    });

    testWidgets('the surface falls back when there are no localisations', (
      tester,
    ) async {
      // A failure early enough that the delegates have not loaded still has to
      // render something. `explain(null)` is that path.
      for (final reason in StartupFailure.values) {
        expect(reason.explain(null), reason.explanation);
      }
    });

    testWidgets('a long message wraps rather than truncating', (tester) async {
      // Truncation on this surface would eat the sentence saying what to do
      // about the failure, and on later screens it would eat a medication
      // name. The rule is the same rule.
      await tester.pumpWidget(
        const DatabaseUnavailableApp(
          reason: StartupFailure.missingCipher,
          deviceLocales: [Locale('bn')],
        ),
      );

      final message = tester.widget<Text>(
        find.text(bn.startupFailureMissingCipher),
      );
      expect(
        message.overflow ?? TextOverflow.clip,
        isNot(TextOverflow.ellipsis),
      );
      expect(message.maxLines, isNull);
    });
  });

  group('the English ARB and the no-localisations fallback agree', () {
    // Two copies of the same sentence exist on purpose: the ARB one, and the
    // fixed constant the surface renders when nothing is loaded. They must say
    // the same thing, or a user on a broken build reads a message that was
    // edited once and not twice.
    test('every startup reason', () {
      for (final reason in StartupFailure.values) {
        expect(reason.explain(en), reason.explanation, reason: '$reason');
      }
    });

    test('the title', () {
      expect(en.startupFailureTitle, startupFailureFallbackTitle);
    });
  });

  group('the eleven live keys are all present in both ARB files', () {
    // The keys the error model and the startup surface name. A key that no
    // longer resolves is a blank message on a screen nobody tests in that
    // language, so the hierarchy is walked rather than trusted.
    final bnKeys = _arb('app_bn.arb').keys.toSet();
    final enKeys = _arb('app_en.arb').keys.toSet();

    test('the five AppFailure keys', () {
      for (final failure in appFailureVariants) {
        expect(bnKeys, contains(failure.localisationKey));
        expect(enKeys, contains(failure.localisationKey));
      }
      expect(appFailureVariants, hasLength(5));
    });

    test('the six StartupFailure keys', () {
      for (final reason in StartupFailure.values) {
        expect(bnKeys, contains(reason.localisationKey));
        expect(enKeys, contains(reason.localisationKey));
      }
      expect(StartupFailure.values, hasLength(6));
    });

    test('every AppFailure variant resolves to a distinct message', () {
      final messages = appFailureVariants
          .map((failure) => failure.message(bn))
          .toList();

      expect(messages.toSet(), hasLength(messages.length));
      for (final message in messages) {
        expect(message.trim(), isNotEmpty);
      }
    });

    test('an AppFailure message never carries its error type', () {
      // `UnexpectedFailure` records a `Type` for diagnostics. It is not
      // something to show a reader, and interpolating it here would be the
      // first crack in the no-free-text rule.
      const failure = UnexpectedFailure(errorType: StateError);
      expect(failure.message(en), isNot(contains('StateError')));
      expect(failure.message(en), en.failureUnexpected);
    });
  });

  group('the app surface', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    testWidgets('renders Bangla with Bengali numerals by default', (
      tester,
    ) async {
      final controller = LocaleController(language: AppLanguage.bangla);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        JotnoApp(database: database, localeController: controller),
      );
      await tester.pumpAndSettle();

      // The schema version is the only number this screen shows, and it goes
      // through the shared formatter. `2`, not `২`, would mean a widget
      // called `toString()` on it.
      expect(find.text(bn.databaseReady('২')), findsOneWidget);
      expect(_renderedText(tester), isNot(contains('2')));
    });

    testWidgets('switching language updates every string without a restart', (
      tester,
    ) async {
      // The acceptance criterion. No `pumpWidget` between the switch and the
      // assertion: the tree is the same tree, rebuilt.
      final controller = LocaleController(
        language: AppLanguage.bangla,
        store: EphemeralLanguageStore(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        JotnoApp(database: database, localeController: controller),
      );
      await tester.pumpAndSettle();
      expect(find.text(bn.databaseReady('২')), findsOneWidget);

      await controller.setLanguage(AppLanguage.english);
      await tester.pumpAndSettle();

      expect(find.text(en.databaseReady('2')), findsOneWidget);
      expect(find.text(bn.databaseReady('২')), findsNothing);
    });

    testWidgets('the numeric run sets tabular figures', (tester) async {
      final controller = LocaleController(language: AppLanguage.bangla);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        JotnoApp(database: database, localeController: controller),
      );
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text(bn.databaseReady('২')));
      expect(
        text.style?.fontFeatures?.map((feature) => feature.feature),
        contains('tnum'),
      );
    });
  });
}
