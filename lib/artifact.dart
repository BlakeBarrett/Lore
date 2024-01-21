import 'package:Lore/md5_utils.dart';

class Artifact {
  final String path;
  final String md5sum;

  final String? mimeType;
  final int? length;

  const Artifact(
      {required this.path, required this.md5sum, this.mimeType, this.length});

  factory Artifact.fromURI(final Uri uri) {
    final String value = uri.toString().endsWith('/')
        ? uri.toString().substring(0, uri.toString().length - 1)
        : uri.toString();
    return Artifact(path: value, md5sum: md5SumFor(value));
  }

  factory Artifact.fromMd5(final String value) {
    return Artifact(path: '', md5sum: value);
  }

  String get name => (path.isNotEmpty)
      ? path
          .substring(path.lastIndexOf('/') + 1)
          .substring(path.lastIndexOf('\\') + 1)
      : '';

  @override
  String toString() {
    return '$md5sum $path';
  }
}
