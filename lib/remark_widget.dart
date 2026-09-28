import 'package:lore/remark.dart';
import 'package:flutter/material.dart';
import 'package:lore/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Machine-readable timestamp format. Used verbatim in tests; the UI uses
/// the locale-aware [DateFormat.yMd] + [DateFormat.Hms] pair instead.
const String kMachineTimestampFormat = 'yyyy-MM-dd HH:mm:ss';

class RemarkWidget extends StatelessWidget {
  const RemarkWidget({
    super.key,
    required this.remark,
    required this.currentUser,
    this.onDeleteRemark,
  });
  final Remark remark;
  final String currentUser;
  final void Function(Remark remark)? onDeleteRemark;

  static final DateFormat _defaultFormatter =
      DateFormat(kMachineTimestampFormat);

  /// Locale-aware display format (e.g. `9/25/2026 3:04:05 PM` for en-US,
  /// `25.09.2026 15:04:05` for de). Built per locale and cached so the
  /// regex/pattern work happens once per locale, not once per row.
  static final Map<String, DateFormat> _localeFormatters =
      <String, DateFormat>{};

  static DateFormat _formatterFor(final BuildContext context) {
    final String localeName = Localizations.localeOf(context).toString();
    return _localeFormatters.putIfAbsent(
        localeName, () => DateFormat.yMd(localeName).add_Hms());
  }

  String getFormattedDate(final Remark value, final BuildContext context) =>
      value.timestamp == null
          ? ''
          : _formatterFor(context).format(value.timestamp!.toLocal());

  /// Test-visible escape hatch for asserting exact machine timestamps.
  @visibleForTesting
  static String formatMachine(final DateTime timestamp) =>
      _defaultFormatter.format(timestamp.toLocal());

  PopupMenuButton<String>? getContextMenu(
      final BuildContext context, final Remark remark) {
    if (remark.author == currentUser) {
      return PopupMenuButton<String>(
        // WCAG 4.1.2: the icon-only menu button needs an accessible name.
        tooltip: AppLocalizations.of(context)?.deleteMenu,
        onSelected: (final value) async {
          if (value != 'delete') return;
          // Destructive action: confirm first (Material: destructive
          // actions ask before they act). No-arg callbacks (widget tests
          // that wire no handler) are unaffected.
          final AppLocalizations? l10n = AppLocalizations.of(context);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (final dialogContext) => AlertDialog(
              content: Text(l10n?.deleteRemarkConfirm ??
                  'Delete this remark?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n?.delete ?? 'Delete'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
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
    final AppLocalizations? l10n = AppLocalizations.of(context);
    // Placeholder message, not string concatenation: word order and
    // punctuation belong to the locale (i18n). Own remarks render as
    // "You" instead of announcing a raw UUID (a11y + readability).
    final String authorDisplay =
        (remark.author != null && remark.author == currentUser)
            ? (l10n?.remarkYou ?? 'You')
            : (remark.author ?? '');
    final String authorLabel = l10n?.remarkAuthorLabel(authorDisplay) ??
        'Author: $authorDisplay';
    return ListTile(
      title: SelectableText(remark.text),
      trailing: getContextMenu(context, remark),
      // WCAG 1.3.1/4.1.2: the 12px author icon + timestamp read as one
      // subtitled unit; the icon alone would be unnamed.
      subtitle: Semantics(
        label: authorLabel,
        // No FittedBox: scaleDown shrank the already-labelSmall (12px)
        // date below legibility in long-locale formats (e.g.
        // "September 28, 2026 10:41:32 PM"). The date ellipsizes instead.
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0, right: 8.0),
              child: Tooltip(
                message: authorLabel,
                child: Icon(
                  Icons.account_circle_sharp,
                  size: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            Flexible(
              child: Text(
                getFormattedDate(remark, context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
