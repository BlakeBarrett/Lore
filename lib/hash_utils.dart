import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 helpers, computed alongside the existing MD5 identity (see
/// `lib/md5_utils.dart`). Prepared so a future MD5 -> SHA-256 primary-key
/// migration has the data; MD5 remains the join key for now.

String sha256SumFor(final String input) {
  final content = utf8.encode(input);
  return sha256.convert(content).toString();
}

Future<String> sha256FromStream(final Stream<List<int>> byteStream) async {
  final bytes = <int>[];
  await for (final chunk in byteStream) {
    bytes.addAll(chunk);
  }
  return sha256.convert(bytes).toString();
}
