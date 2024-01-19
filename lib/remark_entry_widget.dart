import 'package:flutter/material.dart';

class RemarkEntryWidget extends StatefulWidget {
  const RemarkEntryWidget(
      {super.key,
      required this.onSubmitted,
      this.enabled = true,
      this.onTap,
      this.onLogin});

  final bool enabled;
  final Function(String value) onSubmitted;
  final Function()? onTap;
  final Function()? onLogin;

  @override
  State<RemarkEntryWidget> createState() => _RemarkEntryWidgetState();
}

class _RemarkEntryWidgetState extends State<RemarkEntryWidget> {
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
    return Tooltip(
        message: widget.enabled ? 'Add a remark...' : 'Login to add a remark.\r\nClick to login.',
        child: GestureDetector(
            onTap: () {
              if (!widget.enabled) widget.onLogin?.call();
            },
            child: Container(
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
            )));
  }
}
