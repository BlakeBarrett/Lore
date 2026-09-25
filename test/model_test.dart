import 'package:Lore/artifact.dart';
import 'package:Lore/remark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Artifact', () {
    test('fromMap reads name and md5', () {
      final artifact = Artifact.fromMap({
        'name': 'some/dir/file.txt',
        'md5': 'd41d8cd98f00b204e9800998ecf8427e',
      });
      expect(artifact.path, 'some/dir/file.txt');
      expect(artifact.md5sum, 'd41d8cd98f00b204e9800998ecf8427e');
    });

    test('name returns last segment for a path with separators', () {
      final artifact = Artifact(path: 'some/dir/file.txt', md5sum: 'abc');
      expect(artifact.name, 'file.txt');
    });

    test('name returns the whole value when there are no separators', () {
      final artifact = Artifact(path: 'file.txt', md5sum: 'abc');
      expect(artifact.name, 'file.txt');
    });

    test('name is empty for an empty path', () {
      final artifact = Artifact(path: '', md5sum: 'abc');
      expect(artifact.name, '');
    });

    test('== is true for artifacts with the same md5sum', () {
      final a = Artifact(path: 'x/file.txt', md5sum: 'abc');
      final b = Artifact(path: 'y/file.txt', md5sum: 'abc');
      expect(a, equals(b));
    });

    test(
        'hashCode does not throw and is stable for real MD5 values '
        '(regression: old int.parse(radix: 32) threw FormatException)', () {
      final a = Artifact(
          path: 'test/path.txt', md5sum: 'd41d8cd98f00b204e9800998ecf8427e');
      final b = Artifact(
          path: 'test/path.txt', md5sum: 'd41d8cd98f00b204e9800998ecf8427e');
      // The old implementation called int.parse(md5sum.substring(0, 32),
      // radix: 32), which throws FormatException on hex chars like 'd41d8...'.
      expect(() => a.hashCode, returnsNormally);
      expect(a.hashCode, b.hashCode);
    });

    test('fromURI strips a trailing slash and hashes the value', () {
      final artifact = Artifact.fromURI(Uri.parse('https://example.com/'));
      expect(artifact.path, 'https://example.com');
      expect(artifact.md5sum.length, 32);
    });
  });

  group('Remark', () {
    test('fromMap maps remark/user_id/created_at/id', () {
      final remark = Remark.fromMap({
        'remark': 'hello',
        'user_id': 'u-1',
        'created_at': '2026-01-02T03:04:05.000Z',
        'id': 7,
      });
      expect(remark.text, 'hello');
      expect(remark.author, 'u-1');
      expect(remark.id, 7);
      expect(remark.timestamp,
          DateTime.parse('2026-01-02T03:04:05.000Z').toLocal());
    });

    test('fromMap tolerates missing user_id, created_at and stringified ids',
        () {
      final remark = Remark.fromMap({'remark': 'x', 'id': '42'});
      expect(remark.author, isNull);
      expect(remark.timestamp, isNull);
      expect(remark.id, 42);
    });

    test('== and hashCode key on (id ?? timestamp, text)', () {
      final ts = DateTime(2026, 1, 1);
      final a = Remark('hi', 'u', ts, 1);
      final b = Remark('hi', 'other', ts, 1);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final c = Remark('different', 'u', ts, 1);
      expect(a, isNot(equals(c)));
    });

    test('== falls back to timestamp when ids are absent', () {
      final ts = DateTime(2026, 1, 1);
      final a = Remark.simple(text: 'hi', timestamp: ts);
      final b = Remark.simple(text: 'hi', timestamp: ts);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
