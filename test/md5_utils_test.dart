import 'dart:convert';
import 'dart:io';

import 'package:Lore/md5_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MD5 Utils', () {
    test('calculateMD5', () async {
      // Create a temporary file and write some data to it
      var file = File('${Directory.systemTemp.path}/test.txt');
      await file.writeAsString('Hello, world!');

      // Calculate the MD5 hash of the file
      var hash = await calculateMD5(file);

      // Verify the hash
      expect(hash, '6cd3556deb0da54bca060b4c39479839');

      // Clean up
      await file.delete();
    });

    test('md5Convert', () {
      // Convert a string to a list of UTF-8 bytes
      var data = utf8.encode('Hello, world!');

      // Calculate the MD5 hash of the data
      var digest = md5Convert(data);

      // Verify the hash
      expect(digest.toString(), '6cd3556deb0da54bca060b4c39479839');
    });

    test('md5SumFor', () {
      // Calculate the MD5 hash of a string
      var hash = md5SumFor('Hello, world!');

      // Verify the hash
      expect(hash, '6cd3556deb0da54bca060b4c39479839');
    });
  });
}
