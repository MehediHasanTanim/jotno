import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A gate nobody has watched fail is not a gate.
///
/// This runs `tool/l10n_parity_gate.sh` — the same script CI runs — against
/// deliberately unbalanced ARB pairs and asserts that it fails, names the
/// missing key, and names the file it is missing from. It also runs it against
/// the real `lib/l10n`, so the suite fails the moment the two locales diverge
/// rather than waiting for CI.
///
/// The script takes its ARB directory as an argument precisely so this test
/// can point it at a temporary one instead of the repository.
void main() {
  const gate = 'tool/l10n_parity_gate.sh';

  late Directory scratch;

  setUpAll(() {
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
        'is a bash script and CI runs it on ubuntu-latest; there is no point '
        'pretending these tests passed.',
      );
    }
  });

  setUp(() {
    scratch = Directory.systemTemp.createTempSync('l10n_parity_gate');
  });

  tearDown(() {
    if (scratch.existsSync()) {
      scratch.deleteSync(recursive: true);
    }
  });

  /// Runs the gate. With no argument it checks the real `lib/l10n`, exactly as
  /// CI invokes it.
  Future<ProcessResult> runGate([String? arbDir]) =>
      Process.run('bash', [gate, ?arbDir]);

  void writeArb(String name, Map<String, Object?> content) {
    File('${scratch.path}/$name')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(content));
  }

  String outputOf(ProcessResult result) => '${result.stdout}${result.stderr}';

  test('the real lib/l10n passes', () async {
    final result = await runGate();

    expect(result.exitCode, 0, reason: outputOf(result));
  });

  test('a balanced pair passes', () async {
    writeArb('app_bn.arb', {'@@locale': 'bn', 'greeting': 'হ্যালো'});
    writeArb('app_en.arb', {'@@locale': 'en', 'greeting': 'Hello'});

    final result = await runGate(scratch.path);

    expect(result.exitCode, 0, reason: outputOf(result));
  });

  test('a key only in Bangla fails, naming the key and the file', () async {
    // The acceptance criterion, proven by planting one rather than assumed.
    writeArb('app_bn.arb', {
      '@@locale': 'bn',
      'greeting': 'হ্যালো',
      'onlyInBangla': 'শুধু বাংলায়',
    });
    writeArb('app_en.arb', {'@@locale': 'en', 'greeting': 'Hello'});

    final result = await runGate(scratch.path);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('onlyInBangla'));
    expect(outputOf(result), contains('app_en.arb'));
  });

  test('a key only in English fails too', () async {
    // The likelier direction in practice: a developer adds a string to the
    // language they are reading while they work.
    writeArb('app_bn.arb', {'@@locale': 'bn', 'greeting': 'হ্যালো'});
    writeArb('app_en.arb', {
      '@@locale': 'en',
      'greeting': 'Hello',
      'onlyInEnglish': 'Only in English',
    });

    final result = await runGate(scratch.path);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('onlyInEnglish'));
    expect(outputOf(result), contains('app_bn.arb'));
  });

  test('every missing key is named, not just the first', () async {
    writeArb('app_bn.arb', {
      '@@locale': 'bn',
      'first': 'এক',
      'second': 'দুই',
      'third': 'তিন',
    });
    writeArb('app_en.arb', {'@@locale': 'en', 'second': 'Two'});

    final result = await runGate(scratch.path);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('"first"'));
    expect(outputOf(result), contains('"third"'));
    expect(outputOf(result), contains('failed on 2 missing key(s)'));
  });

  test('@-metadata is not mistaken for a key', () async {
    // A gate that cries wolf gets switched off. The template locale carries
    // `@key` blocks — descriptions, placeholder types, examples — and the
    // translated locale does not. That is correct ARB, not a parity failure.
    writeArb('app_bn.arb', {
      '@@locale': 'bn',
      'greeting': 'হ্যালো {name}',
      '@greeting': {
        'description': 'A greeting',
        'placeholders': {
          'name': {'type': 'String', 'example': 'রেহানা'},
        },
      },
    });
    writeArb('app_en.arb', {'@@locale': 'en', 'greeting': 'Hello {name}'});

    final result = await runGate(scratch.path);

    expect(result.exitCode, 0, reason: outputOf(result));
  });

  test('a missing directory fails rather than passing blind', () async {
    final result = await runGate('${scratch.path}/does-not-exist');

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('would be blind'));
  });

  test('a directory with no ARB files fails rather than passing', () async {
    final result = await runGate(scratch.path);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('no app_*.arb files'));
  });

  test('a single locale fails rather than passing trivially', () async {
    // One file is always internally consistent. If the second locale is
    // deleted, the gate must notice rather than report a clean run.
    writeArb('app_bn.arb', {'@@locale': 'bn', 'greeting': 'হ্যালো'});

    final result = await runGate(scratch.path);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('at least two locales'));
  });

  test('unparseable JSON fails rather than being skipped', () async {
    File('${scratch.path}/app_bn.arb').writeAsStringSync('{"greeting": ');
    writeArb('app_en.arb', {'@@locale': 'en', 'greeting': 'Hello'});

    final result = await runGate(scratch.path);

    expect(result.exitCode, 1);
    expect(outputOf(result), contains('not valid JSON'));
  });
}
