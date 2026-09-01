import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jotno/core/database/app_database.dart';
import 'package:jotno/core/database/connection.dart';
import 'package:jotno/core/database/database_key.dart';
import 'package:jotno/core/database/sqlite_file_format.dart';
import 'package:sqlite3/common.dart';

/// Regression suite for the black-screen hang.
///
/// An unencrypted build left the app on a black screen with no error on
/// Android, in both debug and release. Every existing test injected
/// `databaseDirectory`, so none of them went through the path startup actually
/// takes — resolve the app-support directory over a platform channel, then
/// throw. This suite closes that gap.
///
/// Every assertion here runs under a timeout. A startup path that hangs is the
/// exact defect being guarded against, so a pending future must fail the test
/// rather than wedge the suite.
const Duration _limit = Duration(seconds: 20);

/// The channel `path_provider` uses. Mocking it — rather than injecting around
/// it — keeps the real resolution code in `resolveDatabaseFile` under test.
const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;
  late List<String> channelCalls;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('jotno_startup_path');
    dbFile = File('${tempDir.path}/$databaseFileName.sqlite');
    channelCalls = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          channelCalls.add(call.method);
          return tempDir.path;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('the composed startup path', () {
    test('resolves its directories through path_provider, not an override', () {
      // Proves this suite is exercising the real resolution path. If a future
      // change starts injecting directories here, this fails and the whole
      // suite stops being a regression test for the reported defect.
      expect(channelCalls, isEmpty);
    });

    test('opens without hanging and writes an encrypted database', () async {
      final database = await openAppDatabase(
        keyProvider: const DevelopmentKeyProvider(key: 'startup-key'),
      ).timeout(_limit, onTimeout: () => throw StateError('startup hung'));

      var closed = false;
      addTearDown(() async {
        if (!closed) await database.close();
      });

      await database
          .customSelect('select 1')
          .get()
          .timeout(_limit, onTimeout: () => throw StateError('warm-up hung'));
      await database.close();
      closed = true;

      // path_provider really was consulted, for both directories.
      expect(channelCalls, contains('getApplicationSupportDirectory'));
      expect(channelCalls, contains('getTemporaryDirectory'));

      expect(dbFile.existsSync(), isTrue);
      final bytes = dbFile.readAsBytesSync();
      expect(bytes.length, greaterThanOrEqualTo(plaintextSqliteHeader.length));
      expect(startsWithPlaintextSqliteHeader(bytes), isFalse);
    });

    test('surfaces MissingCipherError instead of hanging', () async {
      // THE regression test. `openRaw` stands in for a build that shipped
      // upstream SQLite, which cannot otherwise be simulated on a host where
      // the correct library is installed. Everything else — the platform
      // channel, the directory resolution, the composition in
      // `openAppDatabase` — is the real startup path.
      //
      // Before the fix this future never completed: the throw happened inside
      // a `LazyDatabase` opener and `main`'s catch was never reached, so the
      // app sat on a black screen. A hang here now fails the test.
      Object? caught;
      try {
        await openAppDatabase(
          keyProvider: const DevelopmentKeyProvider(key: 'startup-key'),
          openRaw: (_) => _UpstreamSqliteStub(),
        ).timeout(_limit, onTimeout: () => throw StateError('startup hung'));
      } on Object catch (error) {
        caught = error;
      }

      expect(
        caught,
        isA<MissingCipherError>(),
        reason: 'the cipher failure must reach the caller, not vanish',
      );
    });

    test(
      'the cipher failure arrives before any drift object is built',
      () async {
        // The guarantee is that the throw happens in plain awaited code, so no
        // caller has to remember to run a warm-up query for it to appear.
        await expectLater(
          openEncryptedDatabase(
            keyProvider: const DevelopmentKeyProvider(key: 'startup-key'),
            openRaw: (_) => _UpstreamSqliteStub(),
          ).timeout(_limit, onTimeout: () => throw StateError('startup hung')),
          throwsA(isA<MissingCipherError>()),
        );
      },
    );

    test('a failed cipher check leaves no database file behind', () async {
      await expectLater(
        openAppDatabase(
          keyProvider: const DevelopmentKeyProvider(key: 'startup-key'),
          openRaw: (_) => _UpstreamSqliteStub(),
        ).timeout(_limit, onTimeout: () => throw StateError('startup hung')),
        throwsA(isA<MissingCipherError>()),
      );

      expect(dbFile.existsSync(), isFalse);
    });

    test('an empty key surfaces instead of hanging', () async {
      await expectLater(
        openAppDatabase(keyProvider: const DevelopmentKeyProvider(key: '  '))
            .timeout(_limit, onTimeout: () => throw StateError('startup hung')),
        throwsA(isA<EmptyDatabaseKeyError>()),
      );
    });

    test('a wrong key surfaces instead of hanging', () async {
      final first = await openAppDatabase(
        keyProvider: const DevelopmentKeyProvider(key: 'the-right-key'),
      ).timeout(_limit);
      await first.customSelect('select 1').get();
      await first.close();

      await expectLater(
        openAppDatabase(
          keyProvider: const DevelopmentKeyProvider(key: 'the-wrong-key'),
        ).timeout(_limit, onTimeout: () => throw StateError('startup hung')),
        throwsA(isA<DatabaseKeyRejectedException>()),
      );
    });
  });
}

/// A [CommonDatabase] standing in for a build that shipped upstream SQLite:
/// `pragma cipher` comes back empty rather than as an error.
class _UpstreamSqliteStub implements CommonDatabase {
  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    if (sql.trim().toLowerCase() == 'pragma cipher') {
      return ResultSet(const [], const [], const []);
    }
    throw StateError('unexpected statement on the upstream stub: $sql');
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
