import 'package:Lore/remark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

@immutable
class RemarkListWidget extends StatelessWidget {
  RemarkListWidget(
      {super.key,
      required List<Remark>? remarks,
      required String? currentUser,
      Function(Remark remark)? onDeleteRemark})
      : _remarks = remarks,
        _currentUser = currentUser,
        _onDeleteRemark = onDeleteRemark;

  final List<Remark>? _remarks;
  final String? _currentUser;
  final Function(Remark remark)? _onDeleteRemark;
  final ScrollController _scrollController = ScrollController(
    keepScrollOffset: true,
  );
  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  void scrollToBottom() {
    try {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
      );
    } catch (e) {
      debugPrint('$e');
    }
  }

  String getFormattedDate(final Remark value) =>
      formatter.format(value.timestamp.toLocal()).toString();

  PopupMenuButton? getContextMenu(final Remark remark) {
    if (remark.author == _currentUser) {
      return PopupMenuButton(
        onSelected: (final value) {
          if (value == 'delete') {
            _onDeleteRemark?.call(remark);
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              padding: EdgeInsets.zero,
              value: 'delete',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.delete, color: Theme.of(context).iconTheme.color),
                  Text(AppLocalizations.of(context)!.delete),
                ],
              ),
            ),
          ];
        },
      );
    }
    return null;
  }

  @override
  Widget build(final BuildContext context) {
    if (_remarks == null) return const Spacer(flex: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: _remarks.length,
      itemBuilder: (final context, final index) {
        Remark remark = _remarks[index];
        return ListTile(
          title: SelectableText(remark.text),
          trailing: getContextMenu(remark),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, right: 8.0),
                    child: Tooltip(
                      message:
                          '${AppLocalizations.of(context)!.author}: ${remark.author}',
                      child: Icon(
                        Icons.account_circle_sharp,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    getFormattedDate(remark),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ]),
          ),
        );
      },
    );
  }
}
