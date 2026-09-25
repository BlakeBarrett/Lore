import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 helpers, computed alongside the existing MD5 identity (see
/// `lib/md5_utils.dart`). Prepared so a future MD5 -> SHA-256 primary-key
/// migration has the data; MD5 remains the join key for now.

String sha256SumFor(final String input) {
  final content = utf8.encode(input);
  return sha256.convert(content).toString();
}

/// Hashes [byteStream] incrementally: `crypto`'s `sha256` is a
/// `StreamTransformer`, so chunks flow through the hasher one at a time and
/// the whole stream is never buffered in memory.
Future<String> sha256FromStream(final Stream<List<int>> byteStream) async {
  final digest = await byteStream.transform(sha256).first;
  return digest.toString();
}
