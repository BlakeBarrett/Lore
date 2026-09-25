import 'dart:io';

import 'package:Lore/hash_utils.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/remark.dart';

class Artifact {
  final String path;
  final String md5sum;

  /// SHA-256 of the file contents, computed alongside [md5sum] in the
  /// file-drop path. Nullable: rows saved before this column existed (and
  /// string/URI artifacts) have no SHA-256. MD5 remains the join key; this is
  /// the additive data that will let a future migration switch PKs.
  final String? sha256;

  final int? length;
  File? get file => File(path);
  List<Remark>? remarks;

  String get name => (path.isNotEmpty)
      ? path
          .substring(path.lastIndexOf('/') + 1)
          .substring(path.lastIndexOf('\\') + 1)
      : '';

  Artifact({
    required this.path,
    required this.md5sum,
    this.sha256,
    this.length,
    this.remarks,
  });

  factory Artifact.fromMap(final Map<String, dynamic> map) {
    return Artifact(
      path: map['name'] as String,
      md5sum: map['md5'] as String,
      sha256: map['sha256'] as String?,
    );
  }

  factory Artifact.fromURI(final Uri uri) {
    final String value = uri.toString().endsWith('/')
        ? uri.toString().substring(0, uri.toString().length - 1)
        : uri.toString();
    return Artifact(path: value, md5sum: md5SumFor(value));
  }

  factory Artifact.fromAPIResponse(final dynamic value) =>
      Artifact.fromMap(Map<String, dynamic>.from(value as Map));

  static Future<Artifact> fromFile(final File value) async {
    // One stream per hash: a file stream can only be consumed once.
    final md5sum = await calculateMD5(value.openRead());
    final sha256sum = await sha256FromStream(value.openRead());
    final Artifact artifact =
        Artifact(path: value.path, md5sum: md5sum, sha256: sha256sum);
    return artifact;
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
  int get hashCode => md5sum.hashCode;
}
