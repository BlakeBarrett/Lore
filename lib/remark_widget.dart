import 'package:Lore/remark.dart';
import 'package:flutter/material.dart';
import 'package:Lore/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class RemarkWidget extends StatelessWidget {
  RemarkWidget(
      {super.key,
      required this.remark,
      required this.currentUser,
      this.onDeleteRemark});
  final Remark remark;
  final String currentUser;
  final void Function(Remark remark)? onDeleteRemark;

  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  String getFormattedDate(final Remark value) => value.timestamp == null
      ? ''
      : formatter.format(value.timestamp!.toLocal()).toString();

  PopupMenuButton<String>? getContextMenu(final Remark remark) {
    if (remark.author == currentUser) {
      return PopupMenuButton<String>(
        onSelected: (final value) {
          if (value == 'delete') {
            onDeleteRemark?.call(remark);
          }
        },
        itemBuilder: (final context) {
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
    return ListTile(
      title: SelectableText(remark.text),
      trailing: getContextMenu(remark),
      subtitle: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
  }
}
