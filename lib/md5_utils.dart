import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart';
// ignore: implementation_imports
import 'package:crypto/src/digest_sink.dart';
import 'package:flutter/foundation.dart';

Future<String> calculateMD5(final Stream<List<int>> byteStream) async {
  try {
    final sink = DigestSink();
    final input = md5.startChunkedConversion(sink);

    await for (var data in byteStream) {
      input.add(data);
    }
    input.close();
    return sink.value.toString();
  } catch (e) {
    debugPrint('Error calculating MD5 checksum: $e');
    return '';
  }
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
