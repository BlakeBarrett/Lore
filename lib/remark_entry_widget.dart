import 'package:flutter/material.dart';
import 'package:lore/l10n/app_localizations.dart';

class RemarkEntryWidget extends StatefulWidget {
  const RemarkEntryWidget(
      {super.key,
      required this.onSubmitted,
      this.enabled = true,
      this.onTap,
      this.onLogin});

  final bool enabled;
  final void Function(String value) onSubmitted;
  final void Function()? onTap;
  final void Function()? onLogin;

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
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Tooltip(
        message: widget.enabled ? l10n?.addRemarkTooltip : l10n?.loginPrompt,
        child: GestureDetector(
            onTap: () {
              if (!widget.enabled) widget.onLogin?.call();
            },
            child: Container(
              margin: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.surface,
              child: TextField(
                style: Theme.of(context).textTheme.bodyMedium,
                controller: _controller,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (final value) async {
                  widget.onSubmitted(value);
                  _controller.clear();
                },
                onTap: widget.onTap,
                // WCAG 3.3.2: a persistent label, independent of the hint.
                decoration: InputDecoration(
                  labelText: l10n?.addRemark,
                  hintText: l10n?.addRemarkTooltip,
                  border: const OutlineInputBorder(),
                ),
              ),
            )));
  }
}
