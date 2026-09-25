import 'dart:convert';

import 'package:Lore/hash_utils.dart';
import 'package:Lore/md5_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sha256SumFor', () {
    test('matches the known vector for the empty string', () {
      expect(
          sha256SumFor(''),
          'e3b0c44298fc1c149afbf4c8996fb924'
          '27ae41e4649b934ca495991b7852b855');
    });

    test('matches the known vector for "abc"', () {
      expect(
          sha256SumFor('abc'),
          'ba7816bf8f01cfea414140de5dae2223'
          'b00361a396177a9cb410ff61f20015ad');
    });

    test('returns 64 lowercase hex characters', () {
      final sum = sha256SumFor('some artifact contents');
      expect(sum.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(sum), isTrue);
    });

    test('differs from md5 for the same input', () {
      const input = 'some artifact contents';
      expect(sha256SumFor(input), isNot(md5SumFor(input)));
    });
  });

  group('sha256FromStream', () {
    test('equals sha256SumFor of the joined string across chunked input',
        () async {
      const text = 'the quick brown fox jumps over the lazy dog';
      final bytes = utf8.encode(text);
      // Split into several chunks to exercise the incremental path.
      final chunks = <List<int>>[
        bytes.sublist(0, 10),
        bytes.sublist(10, 25),
        bytes.sublist(25),
      ];
      final fromStream =
          await sha256FromStream(Stream<List<int>>.fromIterable(chunks));
      expect(fromStream, sha256SumFor(text));
    });

    test('empty stream equals the empty-string vector', () async {
      final fromStream =
          await sha256FromStream(Stream<List<int>>.fromIterable(<List<int>>[]));
      expect(
          fromStream,
          'e3b0c44298fc1c149afbf4c8996fb924'
          '27ae41e4649b934ca495991b7852b855');
    });
  });
}
