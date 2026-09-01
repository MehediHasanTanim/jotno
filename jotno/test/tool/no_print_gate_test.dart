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

  setUpAll(() {
    // Two things can make every test below fail for a reason that has nothing
    // to do with the gate. Both are worth naming, because the failure a bare
    // `Process.run` produces for either is a bewildering one.
    if (!File(gate).existsSync()) {
      fail(
        'cannot find $gate from ${Directory.current.path}. These tests run the '
        'real gate script, so they must be run with the package root as the '
        'working directory — `flutter test` from jotno/ does that.',
      );
    }
    try {
      final probe = Process.runSync('bash', ['-c', 'exit 0']);
      if (probe.exitCode != 0) {
        fail('bash is present but exited ${probe.exitCode} on a no-op.');
      }
    } on ProcessException catch (error) {
      fail(
        'bash is not available on this machine (${error.message}). The gate '
        'is a bash script and CI runs it on ubuntu-latest; there is no '
        'point pretending these tests passed.',
      );
    }
  });

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('no_print_gate');
  });

  tearDown(() {
    if (scratch.existsSync()) {
      scratch.deleteSync(recursive: true);
    }
  });

  /// Runs the gate. With no arguments it scans the real `lib/`, exactly as CI
  /// invokes it.
  Future<ProcessResult> runGate([List<String> roots = const []]) =>
      Process.run('bash', [gate, ...roots]);

  void writeDart(String name, String contents) {
    final file = File('${scratch.path}/$name');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  }

  String outputOf(ProcessResult result) => '${result.stdout}${result.stderr}';

  test('the real lib/ passes', () async {
    final result = await runGate();

    expect(result.exitCode, 0, reason: outputOf(result));
  });

  group('console calls', () {
    test('a print fails the gate and names the file and line', () async {
      writeDart('offender.dart', '''
void doSomething() {
  final name = 'Rehana Begum';
  ${'print'}(name);
}
''');

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 1);
      expect(outputOf(result), contains('offender.dart:3'));
    });

    test('a debugPrint fails the gate too', () async {
      // `avoid_print` in the analyzer covers `print` and says nothing about
      // `debugPrint`, which writes to exactly the same device log. That gap is
      // the reason this gate exists alongside `flutter analyze`.
      writeDart(
        'offender.dart',
        'void f() { ${'debugPrint'}("metformin"); }\n',
      );

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 1);
      expect(outputOf(result), contains('offender.dart:1'));
    });

    test('debugPrintStack fails the gate', () async {
      writeDart('stack.dart', "void f() { debugPrintStack(label: 'x'); }\n");

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 1);
      expect(outputOf(result), contains('stack.dart:1'));
    });

    test('a clean file passes', () async {
      writeDart('clean.dart', 'int add(int a, int b) => a + b;\n');

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 0, reason: outputOf(result));
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

      expect(result.exitCode, 0, reason: outputOf(result));
    });
  });

  group('the other doors to the device log', () {
    // Closing `print` alone leaves three more ways to write to logcat, none of
    // which the analyzer says anything about.

    test('stdout.writeln fails the gate', () async {
      writeDart('stdio.dart', "void f() { stdout.writeln('diagnosis'); }\n");

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 1);
      expect(outputOf(result), contains('stdio.dart:1'));
    });

    test('stderr.write fails the gate', () async {
      writeDart('stdio.dart', "void f() { stderr.write('diagnosis'); }\n");

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 1);
      expect(outputOf(result), contains('stdio.dart:1'));
    });

    test('importing dart:developer outside the allowlist fails', () async {
      // The ban is on the import rather than the call, because the call can be
      // spelled `log(...)`, `developer.log(...)` or `dev.log(...)` depending
      // on the prefix — but it cannot be made without the import.
      writeDart(
        'sneaky.dart',
        "import 'dart:developer';\nvoid f() { log('metformin 500mg'); }\n",
      );

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 1);
      expect(outputOf(result), contains('sneaky.dart:1'));
      expect(outputOf(result), contains('dart:developer'));
    });

    test('the log writer itself may import dart:developer', () async {
      // The allowlist is a path suffix, so it applies wherever the scan is
      // pointed. Without this the gate would be unpassable by the very file
      // it exists to funnel everything through.
      writeDart(
        'core/logging/log_writer.dart',
        "import 'dart:developer' as developer;\n"
            "void f() { developer.log('app_opened'); }\n",
      );

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 0, reason: outputOf(result));
    });

    test('a second file cannot hide behind the allowlisted one', () async {
      writeDart(
        'core/logging/log_writer.dart',
        "import 'dart:developer' as developer;\n",
      );
      writeDart('sneaky.dart', "import 'dart:developer';\n");

      final result = await runGate([scratch.path]);

      expect(result.exitCode, 1);
      expect(outputOf(result), contains('sneaky.dart:1'));
      expect(outputOf(result), isNot(contains('log_writer.dart:')));
    });
  });

  test('a missing scan root fails rather than passing blind', () async {
    // The failure mode the two existing gates in ci.yaml are also written to
    // avoid: grep exits >= 2 on an unreadable path, and a naive gate reads
    // that as "found nothing, all clear".
    final result = await runGate(['${scratch.path}/does-not-exist']);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('would be blind'));
  });

  test('every offending line is named, not just the first', () async {
    writeDart('first.dart', 'void a() { ${'print'}(1); }\n');
    writeDart('second.dart', 'void b() { ${'print'}(2); }\n');

    final result = await runGate([scratch.path]);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('first.dart:1'));
    expect(outputOf(result), contains('second.dart:1'));
  });

  test('offences across different doors are all reported together', () async {
    writeDart('a.dart', 'void a() { ${'print'}(1); }\n');
    writeDart('b.dart', "void b() { stderr.writeln('x'); }\n");
    writeDart('c.dart', "import 'dart:developer';\n");

    final result = await runGate([scratch.path]);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('a.dart:1'));
    expect(outputOf(result), contains('b.dart:1'));
    expect(outputOf(result), contains('c.dart:1'));
    expect(outputOf(result), contains('failed on 3 line(s)'));
  });
}
