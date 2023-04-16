import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AddCommentWidget extends StatefulWidget {
  final String id;

  const AddCommentWidget({Key? key, required this.id}) : super(key: key);

  @override
  _AddCommentWidgetState createState() => _AddCommentWidgetState();
}

class _AddCommentWidgetState extends State<AddCommentWidget> {
  final TextEditingController _textEditingController = TextEditingController();

  void _addComment() async {
    final commentText = _textEditingController.text.trim();

    final user = FirebaseAuth.instance.currentUser;
    if (commentText.isNotEmpty && user?.displayName != null) {
      final comment = Comment(
          id: const Uuid().v4(),
          userId: user!.uid,
          userName: user.displayName!,
          text: commentText,
          timestamp: DateTime.now().millisecondsSinceEpoch);

      await FirebaseFirestore.instance
          .collection('files')
          .doc(widget.id)
          .collection('comments')
          .doc(comment.id)
          .set(comment.toMap());
    }

    _textEditingController.clear();
  }

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textEditingController,
            decoration: const InputDecoration(hintText: 'Add a comment'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _addComment,
        )
      ],
    );
  }
}

class Comment {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final int timestamp;

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    required this.timestamp,
  });

  Comment.fromMap(Map<String, dynamic> map, {required this.id})
      : assert(map['text'] != null),
        assert(map['userId'] != null),
        assert(map['timestamp'] != null),
        assert(map['userName'] != null),
        text = map['text'],
        userId = map['userId'],
        userName = map['userName'],
        timestamp = map['timestamp'];

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp,
    };
  }
}
