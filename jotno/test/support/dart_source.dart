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
/// `flutter test` runs with the package root as the working directory. If that
/// ever stops being true this throws rather than silently passing on an empty
/// string.
String readPackageSource(String relativePath) {
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
String withoutComments(String source) {
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
    withoutComments(readPackageSource(relativePath));
