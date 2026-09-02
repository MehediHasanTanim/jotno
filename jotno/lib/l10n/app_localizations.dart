import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// The application name, shown in the task switcher and as the MaterialApp title.
  ///
  /// In bn, this message translates to:
  /// **'যত্ন'**
  String get appTitle;

  /// The only thing the app renders once the encrypted database is open, until the first real screen lands. Placeholder-driven so the schema number goes through the shared number formatter.
  ///
  /// In bn, this message translates to:
  /// **'এনক্রিপ্ট করা ডেটাবেস স্কিমা সংস্করণ {version}-এ খোলা আছে।'**
  String databaseReady(String version);

  /// Heading of the surface shown when the encrypted database cannot be opened.
  ///
  /// In bn, this message translates to:
  /// **'যত্ন চালু হতে পারছে না'**
  String get startupFailureTitle;

  /// The shipped SQLite library is not the SQLite3MultipleCiphers build, so the database would be written in plaintext.
  ///
  /// In bn, this message translates to:
  /// **'এই বিল্ডে এনক্রিপশন ছাড়া SQLite লাইব্রেরি এসেছে, তাই আপনার রেকর্ড সুরক্ষিত থাকত না। এই অবস্থায় যত্ন ডেটাবেস খুলবে না। অফিসিয়াল বিল্ড থেকে আবার ইনস্টল করুন।'**
  String get startupFailureMissingCipher;

  /// The database key was empty, which in SQLite3MultipleCiphers leaves the file unencrypted rather than failing.
  ///
  /// In bn, this message translates to:
  /// **'যত্ন-কে একটি খালি ডেটাবেস কী দেওয়া হয়েছে, যা আপনার রেকর্ড এনক্রিপ্ট না করেই রেখে দিত। এই অবস্থায় যত্ন ডেটাবেস খুলবে না।'**
  String get startupFailureEmptyKey;

  /// A release build reached the development key provider, so every install would share one key.
  ///
  /// In bn, this message translates to:
  /// **'এই বিল্ডে এমন একটি ডেভেলপমেন্ট কী ব্যবহার হয়েছে যা প্রতিটি ইনস্টলে একই। এই অবস্থায় যত্ন ডেটাবেস খুলবে না। অফিসিয়াল বিল্ড থেকে আবার ইনস্টল করুন।'**
  String get startupFailureDevelopmentKeyInRelease;

  /// The cipher is present but the key does not unlock the existing database file.
  ///
  /// In bn, this message translates to:
  /// **'এই ফোনে থাকা ডেটাবেস হাতে থাকা কী দিয়ে খোলা যায়নি। আপনার রেকর্ড এখনও ফোনে এনক্রিপ্ট করা আছে এবং বদলায়নি।'**
  String get startupFailureKeyRejected;

  /// Startup did not finish inside the watchdog timeout.
  ///
  /// In bn, this message translates to:
  /// **'এই ফোনে যত্ন চালু হওয়া শেষ করতে পারেনি। কোনো তথ্য বদলায়নি। অ্যাপটি আবার খুলে দেখুন।'**
  String get startupFailureTimedOut;

  /// Anything else — corruption, a locked file, an I/O error. Deliberately says nothing it cannot prove.
  ///
  /// In bn, this message translates to:
  /// **'এই ফোনে ডেটাবেস খোলা যায়নি।'**
  String get startupFailureUnknown;

  /// StorageFailure — the local database itself failed: disk full, file locked, I/O error.
  ///
  /// In bn, this message translates to:
  /// **'এই ফোনে তথ্য সংরক্ষণ করা যায়নি। আপনার রেকর্ড বদলায়নি।'**
  String get failureStorage;

  /// ValidationFailure — input was rejected before anything was written. Names no field and no value, because both are health data by default.
  ///
  /// In bn, this message translates to:
  /// **'এই তথ্য সংরক্ষণ করা যায়নি। যা লিখেছেন তা দেখে আবার চেষ্টা করুন।'**
  String get failureValidation;

  /// NotFoundFailure — the requested record does not exist, or is soft-deleted.
  ///
  /// In bn, this message translates to:
  /// **'এই রেকর্ডটি আর এই ফোনে নেই।'**
  String get failureNotFound;

  /// PermissionFailure — the operating system withheld a permission the operation needed.
  ///
  /// In bn, this message translates to:
  /// **'এই কাজের জন্য যে অনুমতি দরকার, যত্ন-এর তা নেই। ফোনের সেটিংস থেকে অনুমতিটি দিতে পারেন।'**
  String get failurePermission;

  /// UnexpectedFailure — something nobody anticipated happened inside a boundary.
  ///
  /// In bn, this message translates to:
  /// **'কিছু একটা ভুল হয়েছে। কোনো তথ্য বদলায়নি।'**
  String get failureUnexpected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
