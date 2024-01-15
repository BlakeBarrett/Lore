class Artifact {
  final String path;
  final String md5sum;

  final String? mimeType;
  final int? length;

  const Artifact(this.path, this.md5sum, {this.mimeType, this.length});

  String get name =>
      (path.isNotEmpty) ? path.substring(path.lastIndexOf('/') + 1).substring(path.lastIndexOf('\\') + 1) : '';

  @override
  String toString() {
    return '$md5sum $path';
  }
}
