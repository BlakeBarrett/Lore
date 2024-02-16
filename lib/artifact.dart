import 'dart:io';

import 'package:Lore/lore_api.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/remark.dart';

class Artifact {
  final String path;
  final String md5sum;

  final int? length;
  File? get file => File(path);
  List<Remark>? remarks;

  String get name => (path.isNotEmpty)
      ? path
          .substring(path.lastIndexOf('/') + 1)
          .substring(path.lastIndexOf('\\') + 1)
      : '';

  Artifact({required this.path, required this.md5sum, this.length}) {}

  factory Artifact.fromURI(final Uri uri) {
    final String value = uri.toString().endsWith('/')
        ? uri.toString().substring(0, uri.toString().length - 1)
        : uri.toString();
    return Artifact(path: value, md5sum: md5SumFor(value));
  }

  static Future<Artifact> fromMd5(final String value) async {
    return await LoreAPI.loadArtifact(value) ??
        Artifact(path: '', md5sum: value);
  }

  factory Artifact.fromAPIResponse(final dynamic value) {
    return Artifact(path: value['name'], md5sum: value['md5']);
  }

  static Future<Artifact> fromFile(final File value) async {
    final byteStream = value.openRead();
    final md5sum = await calculateMD5(byteStream);
    final Artifact artifact = Artifact(path: value.path, md5sum: md5sum);
    return artifact;
  }

  Future<List<Remark>> refreshRemarks() async {
    return await LoreAPI.loadRemarks(md5sum: md5sum)
        .then((values) => remarks = values);
  }

  @override
  String toString() {
    return '$md5sum $path';
  }

  @override
  bool operator ==(final Object other) {
    return (other is Artifact) && (other.md5sum == md5sum);
  }

  @override
  int get hashCode => int.parse(md5sum.substring(0, 32), radix: 32);
}
