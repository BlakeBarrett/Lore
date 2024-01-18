class Remark {
  final String text;
  final String author;
  final DateTime timestamp;

  const Remark(this.text, this.author, this.timestamp);
  Remark.fromAPIResponse(final Map<String, dynamic> response)
      : text = response['remark'],
        author = response['user_id'],
        timestamp = DateTime.parse(response['created_at']).toLocal();

  static DateTime getTimeStamp(final String value) =>
      DateTime.parse(value).toLocal();

  static List<Remark> get dummyData => [
        Remark('First!', 'me', DateTime.now()),
        Remark('This is the best version of this file I\'ve found.', 'them',
            DateTime.now()),
        Remark(
            'When I downloaded this file, the mirror was slow and kept resetting.',
            'them',
            DateTime.now()),
        Remark('This file was scanned for viruses and is safe to use.', 'me',
            DateTime.now()),
      ];
}
