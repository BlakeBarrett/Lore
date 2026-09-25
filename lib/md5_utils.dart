import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

Future<String> calculateMD5(final Stream<List<int>> byteStream) async {
  // Public-API replacement for crypto's private DigestSink: the callback
  // fires synchronously when the chunked conversion is closed.
  Digest? digest;
  final sink = ChunkedConversionSink<Digest>.withCallback((final digests) {
    digest = digests.single;
  });
  final input = md5.startChunkedConversion(sink);
  try {
    await for (var data in byteStream) {
      input.add(data);
    }
    input.close();
  } catch (e) {
    debugPrint('Error calculating MD5 checksum: $e');
    return '';
  }
  return digest?.toString() ?? '';
}

Digest md5Convert(final List<int> data) {
  final content = utf8.encode(utf8.decode(data));
  final digest = md5.convert(content);
  return digest;
}

String md5SumFor(final String input) {
  final content = utf8.encode(input);
  final digest = md5.convert(content);
  return digest.toString();
}
