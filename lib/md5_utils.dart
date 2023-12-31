import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

Future<String> calculateMD5(File file) async {
  try {
    var md5 = md5Convert(await file.readAsBytes());
    return md5.toString();
  } catch (e) {
    print('Error calculating MD5 checksum: $e');
    return '';
  }
}

Digest md5Convert(List<int> data) {
  var content = utf8.encode(utf8.decode(data));
  var digest = md5.convert(content);
  return digest;
}

// void main() async {
//   // Example: Replace this with your file path
//   var file = File('/path/to/your/file.txt');

//   var md5Checksum = await calculateMD5(file);
//   print('MD5 Checksum: $md5Checksum');
// }
