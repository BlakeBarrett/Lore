import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoreHomePage(),
    );
  }
}

class LoreHomePage extends StatelessWidget {
  const LoreHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LORE'),
      ),
      body: const ArtifactViewWidget(),
    );
  }
}

class ArtifactViewWidget extends StatelessWidget {
  const ArtifactViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0, // Makes the container square
      child: Container(
        color: Colors.blue,
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () => Scaffold.of(context)
                    .showBottomSheet((context) => const CommentBottomSheet()),
                child: const Text('Your Box Content')),
          ],
        ),
      ),
    );
  }
}

class CommentBottomSheet extends StatefulWidget {
  const CommentBottomSheet({super.key});

  @override
  _CommentBottomSheetState createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 400,
      child: const Expanded(
        child: Column(
          children: [
            CommentArea(),
            CommentInputArea(),
          ],
        ),
      ),
    );
  }
}

class CommentArea extends StatelessWidget {
  const CommentArea({super.key});

  @override
  Widget build(BuildContext context) {
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
  Widget build(BuildContext context) {
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
