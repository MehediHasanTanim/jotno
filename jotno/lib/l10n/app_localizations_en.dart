// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Jotno';

  @override
  String databaseReady(String version) {
    return 'The encrypted database is open at schema version $version.';
  }

  @override
  String get startupFailureTitle => 'Jotno cannot start';

  @override
  String get startupFailureMissingCipher =>
      'This build shipped an unencrypted SQLite library, so your records would not be protected. Jotno will not open the database in that state. Reinstall from an official build.';

  @override
  String get startupFailureEmptyKey =>
      'Jotno was given an empty database key, which would leave your records unencrypted. Jotno will not open the database in that state.';

  @override
  String get startupFailureDevelopmentKeyInRelease =>
      'This build uses a development key that is the same on every install. Jotno will not open the database in that state. Reinstall from an official build.';

  @override
  String get startupFailureKeyRejected =>
      'The database on this device could not be unlocked with the key available. Your records are still encrypted on disk and have not been changed.';

  @override
  String get startupFailureTimedOut =>
      'Jotno could not finish starting up on this device. Nothing has been changed. Try opening the app again.';

  @override
  String get startupFailureUnknown =>
      'The database could not be opened on this device.';

  @override
  String get failureStorage =>
      'Something went wrong saving to this device. Your records have not been changed.';

  @override
  String get failureValidation =>
      'That could not be saved. Check what you entered and try again.';

  @override
  String get failureNotFound => 'That record is no longer on this device.';

  @override
  String get failurePermission =>
      'Jotno does not have the permission this needs. You can grant it in your phone\'s settings.';

  @override
  String get failureUnexpected =>
      'Something went wrong. Nothing has been changed.';
}
