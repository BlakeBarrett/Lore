import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class CommentSection extends StatefulWidget {
  final DatabaseReference commentsRef;
  const CommentSection(this.commentsRef, {Key? key}) : super(key: key);

  @override
  _CommentSectionState createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();
  User? _user;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  void _getUser() async {
    User? user = _auth.currentUser;
    setState(() {
      _user = user;
    });
  }

  void _postComment() {
    String comment = _commentController.text;
    if (comment.trim().isNotEmpty) {
      widget.commentsRef.push().set({
        'text': comment,
        'user': {
          'id': _user?.uid,
          'name': _user?.displayName,
          'photoUrl': _user?.photoURL,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _commentController.clear();
    }
  }

  Widget _buildCommentTile(final DataSnapshot snapshot) {
    final Map<dynamic, dynamic> comment =
        snapshot.value as Map<dynamic, dynamic>;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: comment['user']['photoUrl'] != null
            ? NetworkImage(comment['user']['photoUrl'])
            : null,
        child: comment['user']?['photoUrl'] == null
            ? Text(comment['user']['name'][0])
            : null,
      ),
      title: Text(comment['user']['name']),
      subtitle: Text(comment['text']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_user != null)
          ListTile(
            leading: CircleAvatar(
              backgroundImage: _user?.photoURL != null
                  ? NetworkImage(_user!.photoURL!)
                  : null,
              child:
                  _user?.photoURL == null ? Text(_user!.displayName![0]) : null,
            ),
            title: TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
              ),
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              onChanged: (value) {
                setState(() {});
              },
            ),
            trailing: TextButton(
              onPressed:
                  _commentController.text.trim().isEmpty ? null : _postComment,
              child: const Text('Post'),
            ),
          ),
        StreamBuilder<DatabaseEvent>(
          stream: widget.commentsRef.orderByChild('timestamp').onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }
            if (snapshot.data!.snapshot.value == null) {
              return const Text('No comments yet.');
            }
            final value =
                snapshot.data?.snapshot.value as Map<dynamic, dynamic>;
            final List<DataSnapshot> comments = List.from(value.values);
            return Column(
              children: comments
                  .map((comment) => _buildCommentTile(comment))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
