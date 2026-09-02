import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../result/app_failure.dart';
import '../result/boundary.dart';
import '../result/result.dart';

/// The languages Jotno ships.
///
/// Two, both complete. There is no partial third: `tool/l10n_parity_gate.sh`
/// fails the build on a key present in one ARB and missing from the other, so
/// adding a language here without finishing it is not a state the repository
/// can be left in.
enum AppLanguage {
  /// Bangla. The default, and the template ARB.
  bangla('bn'),

  /// English. A setting, not a fallback.
  english('en');

  const AppLanguage(this.languageCode);

  /// The ISO 639-1 code. This is what is persisted and what `intl` is given.
  ///
  /// A literal constant rather than the enum's `name`, for the same reason
  /// every localisation key in this codebase is: a rename or an obfuscated
  /// release build must not be able to change what a stored row means.
  final String languageCode;

  /// The [Locale] this language renders in.
  Locale get locale => Locale(languageCode);

  /// The language stored as [code], or null if [code] names none.
  ///
  /// Null rather than a throw or a silent default: a row holding something
  /// unrecognisable is a corrupt setting, and the caller — [resolveLanguage] —
  /// treats it as "no choice recorded" and re-derives from the device.
  static AppLanguage? forCode(String? code) {
    for (final language in AppLanguage.values) {
      if (language.languageCode == code) {
        return language;
      }
    }
    return null;
  }

  /// The language [locale] is written in, defaulting to [AppLanguage.bangla].
  ///
  /// Only the language subtag is considered: `en_GB`, `en_US` and `en` are all
  /// English, and everything that is not English is Bangla.
  static AppLanguage forLocale(Locale locale) =>
      forCode(locale.languageCode) ?? AppLanguage.bangla;
}

/// The locales the app declares to the framework.
///
/// Bangla first. `supportedLocales.first` is what Flutter's own resolution
/// falls back to when it can match nothing, so the order is the default.
const List<Locale> supportedLocales = <Locale>[Locale('bn'), Locale('en')];

/// Which language to render in.
///
/// The rule, in order:
///
/// 1. An explicit [storedChoice] wins, whatever the device says. A user who
///    picked English keeps English on a Bangla phone, and the reverse.
/// 2. Otherwise, English **only** if the device's primary locale is English.
/// 3. Otherwise Bangla.
///
/// Step 3 is the point of the story and the thing that is easy to get subtly
/// wrong. The rule is *not* "Bangla if the device says Bangla, else English".
/// A phone set to Arabic, Hindi or Spanish gets Bangla, because Jotno is a
/// Bangla product and English is the exception it makes, not the ground state.
/// A Bangladeshi user on a phone set to English is the common case, and that
/// user has opted out explicitly — which is why English is read off the device
/// at all.
///
/// Only [deviceLocales]`.first` is consulted. Using the whole preference list
/// would resolve `[ar, en]` — an Arabic speaker who also reads English — to
/// English, which is exactly the fallback this rule exists to refuse.
AppLanguage resolveLanguage({
  AppLanguage? storedChoice,
  List<Locale> deviceLocales = const <Locale>[],
}) {
  if (storedChoice != null) {
    return storedChoice;
  }
  if (deviceLocales.isEmpty) {
    return AppLanguage.bangla;
  }
  return deviceLocales.first.languageCode == AppLanguage.english.languageCode
      ? AppLanguage.english
      : AppLanguage.bangla;
}

/// Where the user's language choice is kept between launches.
///
/// An interface rather than a direct database call so that [LocaleController]
/// can be driven in a widget test without an encrypted SQLite file, and so
/// that the one surface which *cannot* have a store — the startup error
/// surface, which renders precisely when the database will not open — is a
/// missing implementation rather than a special case inside the controller.
///
/// Reads and writes return an [AppResult]: a settings row is storage like any
/// other, and a failure to read it must degrade to "no choice recorded"
/// rather than take the app down. See `DatabaseLanguageStore`.
abstract interface class LanguageStore {
  /// The stored choice, or null if the user has never made one.
  FutureResult<AppLanguage?> read();

  /// Records [language] as the user's choice.
  FutureResult<void> write(AppLanguage language);
}

/// The current language, and the only thing permitted to change it.
///
/// A [ChangeNotifier] rather than a Riverpod provider because Riverpod is not
/// a dependency yet and this story may not add one. When it arrives, this
/// class is what the provider exposes; nothing about the surfaces changes.
///
/// Listeners are notified before the write completes — see [setLanguage].
final class LocaleController extends ChangeNotifier {
  /// Creates a controller already resolved to [language].
  ///
  /// Prefer [LocaleController.load], which applies [resolveLanguage] to a
  /// stored choice read from [store]. This constructor exists for the tests
  /// and for the callers that have no store at all.
  factory LocaleController({
    required AppLanguage language,
    LanguageStore? store,
  }) => LocaleController._(language, store);

  LocaleController._(this._language, this._store);

  /// Reads the stored choice and resolves the language to render in.
  ///
  /// A read failure is not an error the user can act on and must not stop the
  /// app: it degrades to "no choice recorded", which resolves from
  /// [deviceLocales] exactly as a fresh install does.
  static Future<LocaleController> load({
    required LanguageStore store,
    List<Locale> deviceLocales = const <Locale>[],
  }) async {
    final stored = (await store.read()).valueOr(null);
    return LocaleController(
      language: resolveLanguage(
        storedChoice: stored,
        deviceLocales: deviceLocales,
      ),
      store: store,
    );
  }

  final LanguageStore? _store;
  AppLanguage _language;

  /// The language every surface under this controller renders in.
  AppLanguage get language => _language;

  /// The locale to hand to `MaterialApp`.
  Locale get locale => _language.locale;

  /// Switches to [language] and persists the choice.
  ///
  /// Notifies listeners first and awaits the write second, deliberately. The
  /// switch is a display change with no data at stake; making the reader watch
  /// a disk write before the screen turns over would be the wrong trade, and
  /// the write is a settings row, not a record.
  ///
  /// The returned result reports whether the choice will survive a relaunch.
  /// A caller that ignores it gets a language switch that works until the app
  /// is closed, which is the correct degradation and not a crash.
  FutureResult<void> setLanguage(AppLanguage language) async {
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
    final store = _store;
    if (store == null) {
      return const Success<void, AppFailure>(null);
    }
    return store.write(language);
  }
}

/// A [LanguageStore] backed by nothing, for surfaces that have no database.
///
/// Reads report no stored choice; writes succeed and are forgotten. Used by
/// tests and available to any future surface that must render before storage
/// exists.
final class EphemeralLanguageStore implements LanguageStore {
  /// Creates a store that starts with [language] recorded, or nothing.
  EphemeralLanguageStore([this._language]);

  AppLanguage? _language;

  @override
  FutureResult<AppLanguage?> read() async =>
      Success<AppLanguage?, AppFailure>(_language);

  @override
  FutureResult<void> write(AppLanguage language) async {
    _language = language;
    return const Success<void, AppFailure>(null);
  }
}

/// Converts a settings-row read or write into an [AppResult].
///
/// Exposed so `DatabaseLanguageStore` and any future setting share one
/// classification: anything the store throws is a [StorageFailure], because
/// from the reader's point of view the difference between a locked file and a
/// disk error is nothing they can act on.
FutureResult<T> guardSettingAccess<T>(Future<T> Function() operation) =>
    Boundary.guardAsync(operation, onError: (_) => const StorageFailure());
