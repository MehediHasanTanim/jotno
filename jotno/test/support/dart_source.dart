import 'dart:io';

/// Reading a library's own source back in a test.
///
/// Two of this story's guarantees are about what a *signature* cannot express
/// — `AppLogger` has no parameter that can carry free text, `Result` has no
/// member that can yield null — and one is about a hierarchy Dart cannot
/// enumerate at runtime. None of them can be asserted by calling the code:
/// the whole point is that the offending call would not compile, so it cannot
/// be written in a test either.
///
/// Reading the declaration is the honest way to check a declaration. It is
/// coarse, and it is deliberately coarse: a test that fails when someone adds
/// `Map<String, Object?> extras` is worth more than no test at all, and the
/// failure message points straight at the line that did it.

/// Loads a file by its path relative to the package root.
///
/// Private: every caller must go through [readPackageCode], because reading a
/// file without stripping its comments lets a doc comment satisfy an
/// assertion about the code.
///
/// `flutter test` runs with the package root as the working directory. If that
/// ever stops being true this throws rather than silently passing on an empty
/// string.
String _readPackageSource(String relativePath) {
  final file = File(relativePath);
  if (!file.existsSync()) {
    throw StateError(
      'expected to find $relativePath relative to ${Directory.current.path}. '
      'These tests read source files to check declarations, so a wrong '
      'working directory must fail loudly rather than scan nothing.',
    );
  }
  return file.readAsStringSync();
}

/// Strips `//` and `/* */` comments from [source].
///
/// Prose in a dartdoc mentions the very words these checks look for — this
/// file says "String" several times — so the comments have to go before
/// anything is searched.
///
/// Caveat: a `//` inside a string literal truncates that line. None of the
/// files checked here contain one, and a test failing loudly is the acceptable
/// outcome if one is ever added.
String _withoutComments(String source) {
  final withoutBlockComments = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  return withoutBlockComments
      .split('\n')
      .map((line) {
        final commentStart = line.indexOf('//');
        return commentStart == -1 ? line : line.substring(0, commentStart);
      })
      .join('\n');
}

/// The code of [relativePath] with its comments removed.
String readPackageCode(String relativePath) =>
    _withoutComments(_readPackageSource(relativePath));

/// The shapes, in Dart source, of a field or parameter that can hold text.
///
/// Written out and named rather than inlined at each call site so the test in
/// `app_failure_test.dart` can point them at synthetic snippets and show that
/// each shape is rejected. A guard with a hole in it is worse than no guard:
/// it reads as coverage and provides none. The first version of this matched
/// only `String message;` and let the nullable and initialiser forms through.
const Map<String, String> freeTextShapes = <String, String>{
  // Catches `String x;`, `String? x;`, `String x = '';`, `String x,` and
  // `String x)` — the nullable, initialiser and parameter forms as well as
  // the plain one. `String get foo` and `String toString()` are not caught,
  // because a word and a `(` follow instead.
  'a String field or parameter': r'\bString\??\s+\w+\s*[;=,)]',
  // `List<String>`, `Map<String, ...>` — text smuggled inside a collection.
  'a String inside a generic': r'<\s*String\b',
  // `dynamic` accepts anything, which includes text.
  'a dynamic member': r'\bdynamic\b',
  // `)` is deliberately absent here: `operator ==(Object other)` is forced by
  // Dart's own contract and is the one legitimate `Object` in these files.
  'an Object field': r'\bObject\??\s+\w+\s*[;=,]',
};

/// The free-text shapes [code] contains, by name.
List<String> freeTextShapesIn(String code) => <String>[
  for (final shape in freeTextShapes.entries)
    if (RegExp(shape.value).hasMatch(code)) shape.key,
];
