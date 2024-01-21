import 'package:Lore/remark.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

@immutable
class RemarkListWidget extends StatelessWidget {
  RemarkListWidget({super.key, required List<Remark> remarks})
      : _remarks = remarks;

  final List<Remark> _remarks;
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: true,
  );
  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
    );
  }

  String getFormattedDate(final Remark value) =>
      formatter.format(value.timestamp.toLocal()).toString();
  String getToolTipText(final Remark remark) =>
      'TimeStamp: ${getFormattedDate(remark)}\nAuthor: ${remark.author}';

  @override
  Widget build(final BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: _remarks.length,
      itemBuilder: (final context, final index) {
        Remark remark = _remarks[index];
        return ListTile(
          leading: const Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [Icon(Icons.comment)]),
          title: Text(remark.text),
          subtitle: Tooltip(
              message: getToolTipText(remark),
              child: Text(
                getFormattedDate(remark),
                style: Theme.of(context).textTheme.labelSmall,
              )),
        );
      },
    );
  }
}
