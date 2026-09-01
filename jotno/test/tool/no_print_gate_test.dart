import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A gate nobody has watched fail is not a gate.
///
/// This runs `tool/no_print_gate.sh` — the same script CI runs — against
/// deliberately offending files and asserts that it fails and names the file
/// and line. It also runs it against the real `lib/`, so the suite fails the
/// moment a console call lands there, rather than waiting for CI.
///
/// The script takes its scan roots as arguments precisely so this test can
/// point it at a temporary directory instead of the repository.
void main() {
  const gate = 'tool/no_print_gate.sh';

  late Directory scratch;

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('no_print_gate');
  });

  tearDown(() {
    if (scratch.existsSync()) {
      scratch.deleteSync(recursive: true);
    }
  });

  Future<ProcessResult> runGate(List<String> roots) =>
      Process.run('bash', [gate, ...roots]);

  void writeDart(String name, String contents) {
    File('${scratch.path}/$name').writeAsStringSync(contents);
  }

  test('the real lib/ passes', () async {
    final result = await Process.run('bash', [gate]);

    expect(
      result.exitCode,
      0,
      reason:
          'lib/ contains a direct console call.\n'
          '${result.stdout}${result.stderr}',
    );
  });

  test('a print fails the gate and names the file and line', () async {
    writeDart('offender.dart', '''
void doSomething() {
  final name = 'Rehana Begum';
  ${'print'}(name);
}
''');

    final result = await Process.run('bash', [gate, scratch.path]);
    final output = '${result.stdout}${result.stderr}';

    expect(result.exitCode, 1);
    expect(output, contains('offender.dart'));
    expect(output, contains('offender.dart:3'));
  });

  test('a debugPrint fails the gate too', () async {
    // `avoid_print` in the analyzer covers `print` and says nothing about
    // `debugPrint`, which writes to exactly the same device log. That gap is
    // the reason this gate exists alongside `flutter analyze`.
    writeDart('offender.dart', 'void f() { ${'debugPrint'}("metformin"); }\n');

    final result = await runGate([scratch.path]);

    expect(result.exitCode, 1);
    expect('${result.stdout}', contains('offender.dart:1'));
  });

  test('a clean file passes', () async {
    writeDart('clean.dart', 'int add(int a, int b) => a + b;\n');

    final result = await runGate([scratch.path]);

    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('words merely containing print do not trip it', () async {
    // A gate that cries wolf gets commented out. `sprint`, `blueprint` and a
    // method named `print` on someone's own object are all legitimate.
    writeDart('lookalikes.dart', '''
int sprint(int a) => a;
int blueprint(int a) => a;
void f(Printer p) { p.print(1); }
''');

    final result = await runGate([scratch.path]);

    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('a missing scan root fails rather than passing blind', () async {
    // The failure mode the two existing gates in ci.yaml are also written to
    // avoid: grep exits >= 2 on an unreadable path, and a naive gate reads
    // that as "found nothing, all clear".
    final result = await runGate(['${scratch.path}/does-not-exist']);

    expect(result.exitCode, 1);
    expect('${result.stdout}', contains('would be blind'));
  });

  test('every offending line is named, not just the first', () async {
    writeDart('first.dart', 'void a() { ${'print'}(1); }\n');
    writeDart('second.dart', 'void b() { ${'print'}(2); }\n');

    final result = await runGate([scratch.path]);
    final output = '${result.stdout}';

    expect(result.exitCode, 1);
    expect(output, contains('first.dart:1'));
    expect(output, contains('second.dart:1'));
  });
}
