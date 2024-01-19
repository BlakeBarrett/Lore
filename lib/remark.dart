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
        Remark('First!', '', DateTime.now()),
        Remark('How did I get here?', 'You', DateTime.now()),
        Remark('This is cool, how does it work?', 'You', DateTime.now()),
        Remark(
            'Drop a file from anywhere on your computer into this window to start the conversation around it.',
            'Lore',
            DateTime.now()),
        Remark('What happens to my file?', 'You', DateTime.now()),
        Remark('Your file stays on your computer.', 'Lore', DateTime.now()),
        Remark(
            'A hash is generated and used as a stand in for the file. That\'s what the "md5" field is.',
            'Lore',
            DateTime.now()),
        Remark('Cool! I\'ll see you in the comments.', 'You', DateTime.now()),
      ];
}
