import 'package:Lore/remark.dart';
import 'package:flutter/material.dart';

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
    return ListView.builder(
      controller: _scrollController,
      itemCount: _remarks.length,
      itemBuilder: (context, index) {
        Remark remark = _remarks[index];
        return ListTile(
          leading: const Icon(Icons.comment),
          title: Text(remark.text),
        );
      },
    );
  }
}

class CommentInputArea extends StatefulWidget {
  const CommentInputArea(
      {super.key, required this.onSubmitted, this.enabled = true, this.onTap});

  final bool enabled;
  final Function(String value) onSubmitted;
  final Function()? onTap;

  @override
  State<CommentInputArea> createState() => _CommentInputAreaState();
}

class _CommentInputAreaState extends State<CommentInputArea> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        textInputAction: TextInputAction.send,
        onSubmitted: (value) async {
          widget.onSubmitted(value);
          _controller.clear();
        },
        onTap: widget.onTap,
        decoration: const InputDecoration(
          hintText: 'Add a remark...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
