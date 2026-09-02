/// The line-height rule, which is the most consequential typographic decision
/// in the product.
///
/// Bangla needs a taller line box than Latin at the same size: the script
/// carries matras above the baseline and descenders below it, and conjuncts
/// (যুক্তাক্ষর) stack. Body text therefore sets **15/26 in Bangla against
/// 15/24 in English**.
///
/// The second half of the rule matters more than the first. Every container is
/// sized to the *Bangla* measure — [banglaBodyLineHeight], not the English one
/// — so switching language changes the glyphs and nothing else. Without it the
/// English build would be the one laid out correctly and the Bangla build the
/// one that reflows, wraps differently and pushes a control off screen, which
/// is precisely the retrofit this story exists to avoid.
///
/// This is the metric layer only. The colours, weights and the rest of the
/// type scale are Story 1.4's, and when that theme lands it should build its
/// body styles from here rather than restating the numbers.
library;

import 'package:flutter/material.dart';

import 'locale_controller.dart';

/// The body text size, in logical pixels. The same in both languages.
const double bodyFontSize = 15;

/// The Bangla body line height, in logical pixels.
///
/// **This is the measure every container reserves**, in both languages. It is
/// the taller of the two, so a layout that fits Bangla fits English, and the
/// English build reads as slightly generous rather than the Bangla build
/// reading as cramped.
const double banglaBodyLineHeight = 26;

/// The English body line height, in logical pixels.
///
/// Applied to the text itself so English is not artificially airy inside its
/// own line box. Never used to size a container — see [banglaBodyLineHeight].
const double englishBodyLineHeight = 24;

/// The body line height for [language], in logical pixels.
double bodyLineHeightFor(AppLanguage language) => switch (language) {
  AppLanguage.bangla => banglaBodyLineHeight,
  AppLanguage.english => englishBodyLineHeight,
};

/// The body text style for [language].
///
/// `TextStyle.height` is a multiple of the font size, so the ratio is computed
/// rather than written out: 26/15 and 24/15 are not numbers anyone should be
/// asked to keep in sync by hand.
TextStyle bodyTextStyle(AppLanguage language) => TextStyle(
  fontSize: bodyFontSize,
  height: bodyLineHeightFor(language) / bodyFontSize,
);

/// The height a container must reserve for [lines] lines of body text.
///
/// Always the Bangla measure, whatever language is rendering. A container
/// sized from the active language would be the reflow this rule forbids.
double banglaBodyMeasure(int lines) => banglaBodyLineHeight * lines;

/// A [TextTheme] whose body styles carry the [language] line height.
///
/// Applied to both startup surfaces in `main.dart`. Story 1.4 replaces this
/// with the full scale; until then it is what makes the rule true on screen
/// rather than merely documented.
TextTheme bodyTextTheme(AppLanguage language) {
  final style = bodyTextStyle(language);
  return TextTheme(bodyLarge: style, bodyMedium: style, bodySmall: style);
}
