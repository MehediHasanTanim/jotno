import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

import 'locale_controller.dart';

/// The one way a number reaches a Jotno screen.
///
/// A dose, a reading, a count, a schema version — every one of them goes
/// through here, and a raw `toString()` or `'$value'` on a number in a widget
/// is a review failure. This is not a style preference. The reader of this app
/// reads Bengali numerals (০–৯), and a screen that mixes `১২৪` in one row with
/// `124` in the next is not a Bangla product with a translation applied; it is
/// an English product leaking through.
///
/// The rule is enforceable precisely because there is one entry point. If the
/// digit mapping is ever wrong it is wrong in one place, and the tests in
/// `test/core/l10n/number_format_test.dart` are looking at that place.
///
/// **Why `intl` rather than a digit table.** `NumberFormat` carries the whole
/// locale's numbering conventions, not just its digits: `bn` groups in the
/// Indian style (`১,২৩,৪৫৬` — thousand, then lakh, then crore), which a
/// hand-rolled character substitution over an English-grouped string would get
/// wrong at exactly the sizes where a misread matters. The digits come out of
/// the same table.
@immutable
final class AppNumberFormat {
  const AppNumberFormat._(this._languageCode);

  /// The formatter for [locale].
  ///
  /// Any locale that is not one Jotno ships falls back to Bangla, matching
  /// [resolveLanguage]: the default is Bangla, never English.
  factory AppNumberFormat.of(Locale locale) =>
      AppNumberFormat.forLanguage(AppLanguage.forLocale(locale));

  /// The formatter for [language].
  factory AppNumberFormat.forLanguage(AppLanguage language) =>
      AppNumberFormat._(language.languageCode);

  /// The `intl` locale name the patterns below are built for.
  final String _languageCode;

  /// Cached [intl.NumberFormat] instances.
  ///
  /// Constructing one parses a pattern and looks up the locale's symbols, and
  /// these are called once per number per frame. Keyed by language code and
  /// fraction digits, both of which are closed sets.
  static final Map<String, intl.NumberFormat> _cache =
      <String, intl.NumberFormat>{};

  intl.NumberFormat _formatter({required int fractionDigits}) {
    return _cache.putIfAbsent('$_languageCode:$fractionDigits', () {
      final format = intl.NumberFormat.decimalPattern(_languageCode);
      format.minimumFractionDigits = fractionDigits;
      format.maximumFractionDigits = fractionDigits;
      return format;
    });
  }

  /// Renders a whole number: `124` becomes `১২৪` in Bangla, `124` in English.
  String integer(int value) => _formatter(fractionDigits: 0).format(value);

  /// Renders [value] with exactly [fractionDigits] after the decimal point.
  ///
  /// Fixed rather than "up to", because a column of readings where one row
  /// shows `৩৬.৫` and the next `৩৭` does not scan as a column.
  String decimal(num value, {int fractionDigits = 1}) =>
      _formatter(fractionDigits: fractionDigits).format(value);
}

/// Reaching the formatter for the locale currently in force.
extension AppNumberFormatOnContext on BuildContext {
  /// The number formatter for this subtree's locale.
  ///
  /// `context.numbers.integer(count)` is the whole idiom.
  AppNumberFormat get numbers =>
      AppNumberFormat.of(Localizations.localeOf(this));
}

/// The font features every numeric run in Jotno sets.
///
/// Tabular figures give each digit the same advance width, so a column of
/// readings lines up on the decimal point instead of drifting. Applied here as
/// a bare constant rather than through the theme because the theme is Story
/// 1.4's; when it lands, its numeric text styles should be built from this
/// list rather than repeating it.
const List<FontFeature> tabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
];
