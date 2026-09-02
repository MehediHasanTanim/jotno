// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'যত্ন';

  @override
  String databaseReady(String version) {
    return 'এনক্রিপ্ট করা ডেটাবেস স্কিমা সংস্করণ $version-এ খোলা আছে।';
  }

  @override
  String get startupFailureTitle => 'যত্ন চালু হতে পারছে না';

  @override
  String get startupFailureMissingCipher =>
      'এই বিল্ডে এনক্রিপশন ছাড়া SQLite লাইব্রেরি এসেছে, তাই আপনার রেকর্ড সুরক্ষিত থাকত না। এই অবস্থায় যত্ন ডেটাবেস খুলবে না। অফিসিয়াল বিল্ড থেকে আবার ইনস্টল করুন।';

  @override
  String get startupFailureEmptyKey =>
      'যত্ন-কে একটি খালি ডেটাবেস কী দেওয়া হয়েছে, যা আপনার রেকর্ড এনক্রিপ্ট না করেই রেখে দিত। এই অবস্থায় যত্ন ডেটাবেস খুলবে না।';

  @override
  String get startupFailureDevelopmentKeyInRelease =>
      'এই বিল্ডে এমন একটি ডেভেলপমেন্ট কী ব্যবহার হয়েছে যা প্রতিটি ইনস্টলে একই। এই অবস্থায় যত্ন ডেটাবেস খুলবে না। অফিসিয়াল বিল্ড থেকে আবার ইনস্টল করুন।';

  @override
  String get startupFailureKeyRejected =>
      'এই ফোনে থাকা ডেটাবেস হাতে থাকা কী দিয়ে খোলা যায়নি। আপনার রেকর্ড এখনও ফোনে এনক্রিপ্ট করা আছে এবং বদলায়নি।';

  @override
  String get startupFailureTimedOut =>
      'এই ফোনে যত্ন চালু হওয়া শেষ করতে পারেনি। কোনো তথ্য বদলায়নি। অ্যাপটি আবার খুলে দেখুন।';

  @override
  String get startupFailureUnknown => 'এই ফোনে ডেটাবেস খোলা যায়নি।';

  @override
  String get failureStorage =>
      'এই ফোনে তথ্য সংরক্ষণ করা যায়নি। আপনার রেকর্ড বদলায়নি।';

  @override
  String get failureValidation =>
      'এই তথ্য সংরক্ষণ করা যায়নি। যা লিখেছেন তা দেখে আবার চেষ্টা করুন।';

  @override
  String get failureNotFound => 'এই রেকর্ডটি আর এই ফোনে নেই।';

  @override
  String get failurePermission =>
      'এই কাজের জন্য যে অনুমতি দরকার, যত্ন-এর তা নেই। ফোনের সেটিংস থেকে অনুমতিটি দিতে পারেন।';

  @override
  String get failureUnexpected => 'কিছু একটা ভুল হয়েছে। কোনো তথ্য বদলায়নি।';
}
