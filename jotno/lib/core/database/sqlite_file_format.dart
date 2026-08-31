import 'dart:typed_data';

/// The 16-byte magic string every *unencrypted* SQLite file begins with.
///
/// It is the ASCII text `SQLite format 3` followed by a single NUL — not a
/// space. Getting that last byte wrong makes "this file is not plaintext"
/// assertions pass against a fully plaintext database, so the bytes are
/// spelled out here once, numerically, and shared by every suite that checks
/// them. Do not re-type this constant anywhere else.
const List<int> plaintextSqliteHeader = <int>[
  0x53, // S
  0x51, // Q
  0x4c, // L
  0x69, // i
  0x74, // t
  0x65, // e
  0x20, // (space)
  0x66, // f
  0x6f, // o
  0x72, // r
  0x6d, // m
  0x61, // a
  0x74, // t
  0x20, // (space)
  0x33, // 3
  0x00, // NUL
];

/// Whether [bytes] begins with the unencrypted SQLite header.
///
/// Returns `false` for anything shorter than the header. Callers asserting
/// that a file is *encrypted* must therefore also assert the file is at least
/// [plaintextSqliteHeader] long, or a truncated read passes for free.
bool startsWithPlaintextSqliteHeader(List<int> bytes) {
  if (bytes.length < plaintextSqliteHeader.length) {
    return false;
  }
  for (var i = 0; i < plaintextSqliteHeader.length; i++) {
    if (bytes[i] != plaintextSqliteHeader[i]) {
      return false;
    }
  }
  return true;
}

/// Renders the first [count] bytes of [bytes] as hex, for failure messages.
String describeLeadingBytes(Uint8List bytes, {int count = 16}) {
  final shown = bytes
      .take(count)
      .map((b) => b.toRadixString(16).padLeft(2, '0'));
  return shown.join(' ');
}
