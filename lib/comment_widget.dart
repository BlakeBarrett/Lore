import 'package:flutter/material.dart';

class CommentBottomSheet extends StatelessWidget {
  const CommentBottomSheet({super.key});

  @override
  Widget build(final BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 400,
      child: const Expanded(
        child: CommentInputArea(),
      ),
    );
  }
}

class CommentArea extends StatelessWidget {
  const CommentArea({super.key});

  @override
  Widget build(final BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return const ListTile(
            leading: Icon(Icons.comment),
            title: Text('Comment'),
          );
        },
      ),
    );
  }
}

class CommentInputArea extends StatelessWidget {
  const CommentInputArea({super.key});

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Write a comment...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
