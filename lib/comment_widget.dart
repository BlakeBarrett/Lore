import 'package:flutter/material.dart';

class Remark {
  final String text;
  final String author;
  final DateTime timestamp;

  const Remark(this.text, this.author, this.timestamp);
}

@immutable
class CommentArea extends StatelessWidget {
  CommentArea({super.key, required List<Remark> remarks}) : _remarks = remarks;

  final List<Remark> _remarks;
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: true,
  );

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(final BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _remarks.length,
        itemBuilder: (context, index) {
          Remark remark = _remarks[index];
          return ListTile(
            leading: const Icon(Icons.comment),
            title: Text(remark.text),
          );
        },
      ),
    );
  }
}

class CommentInputArea extends StatelessWidget {
  const CommentInputArea({super.key, required this.onSubmitted});

  final Function(String value) onSubmitted;

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: TextField(
        textInputAction: TextInputAction.send,
        onSubmitted: onSubmitted,
        decoration: const InputDecoration(
          hintText: 'Add a remark...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
