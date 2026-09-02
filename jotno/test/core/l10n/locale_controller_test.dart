import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/l10n/locale_controller.dart';
import 'package:jotno/core/result/app_failure.dart';
import 'package:jotno/core/result/result.dart';
import 'package:jotno/l10n/app_localizations.dart';

/// A store whose reads fail, to prove a broken settings row cannot stop the
/// app from starting.
final class _FailingLanguageStore implements LanguageStore {
  @override
  FutureResult<AppLanguage?> read() async =>
      const Failure<AppLanguage?, AppFailure>(StorageFailure());

  @override
  FutureResult<void> write(AppLanguage language) async =>
      const Failure<void, AppFailure>(StorageFailure());
}

void main() {
  group('resolveLanguage — the matrix this story exists for', () {
    test('fresh install on a Bangla device renders Bangla', () {
      expect(
        resolveLanguage(deviceLocales: const [Locale('bn')]),
        AppLanguage.bangla,
      );
    });

    test('fresh install on an English device renders English', () {
      expect(
        resolveLanguage(deviceLocales: const [Locale('en')]),
        AppLanguage.english,
      );
    });

    test('fresh install on an Arabic device renders Bangla, not English', () {
      // The line the whole story turns on. The rule is not "Bangla if the
      // device says Bangla, else English" — everything that is not explicitly
      // English gets Bangla, because Bangla is the default and English is the
      // opt-out.
      expect(
        resolveLanguage(deviceLocales: const [Locale('ar')]),
        AppLanguage.bangla,
      );
    });

    test('a device with no locale at all renders Bangla', () {
      expect(resolveLanguage(), AppLanguage.bangla);
    });

    test('a stored English choice beats a Bangla device', () {
      expect(
        resolveLanguage(
          storedChoice: AppLanguage.english,
          deviceLocales: const [Locale('bn')],
        ),
        AppLanguage.english,
      );
    });

    test('a stored Bangla choice beats an English device', () {
      expect(
        resolveLanguage(
          storedChoice: AppLanguage.bangla,
          deviceLocales: const [Locale('en')],
        ),
        AppLanguage.bangla,
      );
    });

    test('regional English variants are still English', () {
      for (final locale in const [
        Locale('en'),
        Locale('en', 'US'),
        Locale('en', 'GB'),
        Locale('en', 'IN'),
      ]) {
        expect(
          resolveLanguage(deviceLocales: [locale]),
          AppLanguage.english,
          reason: '$locale',
        );
      }
    });

    test('English further down the preference list does not win', () {
      // An Arabic speaker whose phone also lists English is not an English
      // reader for this app's purposes. Only the primary locale is consulted;
      // taking the whole list would reintroduce English-as-fallback by the
      // back door.
      expect(
        resolveLanguage(deviceLocales: const [Locale('ar'), Locale('en')]),
        AppLanguage.bangla,
      );
    });
  });

  group('AppLanguage', () {
    test('codes are literal constants, not the enum name', () {
      // The code is persisted in the database. Deriving it from `name` would
      // mean an obfuscated release build, or a rename, silently repointed
      // every stored row.
      expect(AppLanguage.bangla.languageCode, 'bn');
      expect(AppLanguage.english.languageCode, 'en');
    });

    test('an unrecognised stored code reads as no choice', () {
      expect(AppLanguage.forCode('xx'), isNull);
      expect(AppLanguage.forCode(''), isNull);
      expect(AppLanguage.forCode(null), isNull);
    });

    test('a locale in no shipped language falls back to Bangla', () {
      expect(AppLanguage.forLocale(const Locale('ar')), AppLanguage.bangla);
    });

    test('supportedLocales matches what gen-l10n produced, in order', () {
      // Bangla first, because `supportedLocales.first` is what Flutter's own
      // resolution falls back to. Compared against the generated list so that
      // adding an ARB file without revisiting the default fails here.
      expect(supportedLocales, AppLocalizations.supportedLocales);
      expect(supportedLocales.first, const Locale('bn'));
    });
  });

  group('LocaleController', () {
    test('loads the stored choice over the device locale', () async {
      final controller = await LocaleController.load(
        store: EphemeralLanguageStore(AppLanguage.english),
        deviceLocales: const [Locale('bn')],
      );

      expect(controller.language, AppLanguage.english);
      expect(controller.locale, const Locale('en'));
    });

    test('falls back to the device locale when nothing is stored', () async {
      final controller = await LocaleController.load(
        store: EphemeralLanguageStore(),
        deviceLocales: const [Locale('ar')],
      );

      expect(controller.language, AppLanguage.bangla);
    });

    test('a store that cannot be read does not stop startup', () async {
      // The settings row lives in the database. A read failure is not
      // something the reader can act on, and refusing to start over it would
      // be a worse outcome than showing the default language.
      final controller = await LocaleController.load(
        store: _FailingLanguageStore(),
        deviceLocales: const [Locale('en')],
      );

      expect(controller.language, AppLanguage.english);
    });

    test('switching notifies listeners once', () async {
      final controller = LocaleController(
        language: AppLanguage.bangla,
        store: EphemeralLanguageStore(),
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLanguage(AppLanguage.english);

      expect(controller.language, AppLanguage.english);
      expect(notifications, 1);
    });

    test(
      'switching to the language already in force notifies nobody',
      () async {
        final controller = LocaleController(language: AppLanguage.bangla);
        addTearDown(controller.dispose);
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.setLanguage(AppLanguage.bangla);

        expect(notifications, 0);
      },
    );

    test('a failed write still switches, and says the write failed', () async {
      // The correct degradation: the language changes on screen and the
      // caller is told it will not survive a relaunch. Not a crash, and not a
      // silent success either.
      final controller = LocaleController(
        language: AppLanguage.bangla,
        store: _FailingLanguageStore(),
      );
      addTearDown(controller.dispose);

      final result = await controller.setLanguage(AppLanguage.english);

      expect(controller.language, AppLanguage.english);
      expect(result, const Failure<void, AppFailure>(StorageFailure()));
    });
  });

  group('the choice survives a relaunch', () {
    // The whole reason the setting lives in the encrypted database rather than
    // in a preferences package. Driven against a real drift database so the
    // settings table, the companion and the upsert are all exercised.

    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => database.close());

    test('a choice written in one session is read back in the next', () async {
      final first = await LocaleController.load(
        store: DatabaseLanguageStore(database),
        deviceLocales: const [Locale('bn')],
      );
      expect(first.language, AppLanguage.bangla);

      expect(
        await first.setLanguage(AppLanguage.english),
        const Success<void, AppFailure>(null),
      );

      // A second controller over the same database is what a relaunch looks
      // like: nothing carried over in memory, everything read from the row.
      final second = await LocaleController.load(
        store: DatabaseLanguageStore(database),
        deviceLocales: const [Locale('bn')],
      );

      expect(second.language, AppLanguage.english);
    });

    test('switching twice leaves one row, not two', () async {
      final store = DatabaseLanguageStore(database);
      await store.write(AppLanguage.english);
      await store.write(AppLanguage.bangla);

      final rows = await database.select(database.appSettings).get();

      expect(rows, hasLength(1));
      expect(rows.single.name, settingLanguage);
      expect(rows.single.value, 'bn');
    });

    test('a corrupt value reads as no choice rather than throwing', () async {
      // A row a future version wrote, or one that got mangled. The device
      // locale answers instead; nothing throws.
      await database.writeSetting(settingLanguage, 'klingon');

      final controller = await LocaleController.load(
        store: DatabaseLanguageStore(database),
        deviceLocales: const [Locale('en')],
      );

      expect(controller.language, AppLanguage.english);
    });

    test('a read on a closed database degrades instead of throwing', () async {
      // Storage failing is not a reason to take the app down over a display
      // setting. The store answers with a `Failure`, and `LocaleController`
      // treats that as "no choice recorded".
      final store = DatabaseLanguageStore(database);
      await store.write(AppLanguage.english);
      await database.close();

      expect((await store.read()).isFailure, isTrue);
      expect((await store.write(AppLanguage.bangla)).isFailure, isTrue);

      final controller = await LocaleController.load(
        store: store,
        deviceLocales: const [Locale('ar')],
      );
      expect(controller.language, AppLanguage.bangla);
    });
  });
}
