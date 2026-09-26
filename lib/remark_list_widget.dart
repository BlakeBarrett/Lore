import 'package:lore/l10n/app_localizations.dart';
import 'package:lore/remark.dart';
import 'package:lore/remark_widget.dart';
import 'package:flutter/material.dart';

/// Reserve at the bottom of the list so the floating remark field never
/// covers the last entry.
const double _kBottomReserveHeight = 80.0;

/// Localizes the [Remark.dummyData] onboarding conversation.
///
/// The dummy entries stay pure data in [Remark] (author identity +
/// timestamps); only the display text is swapped for the matching ARB
/// string, zipped in list order so the script reads identically in every
/// locale. The 'You'/'Lore' author labels render as-is (they read as
/// participant names, not UI copy).
List<Remark> localizedOnboardingRemarks(final AppLocalizations l10n) {
  final List<String> localizedTexts = <String>[
    l10n.onboardingFirst,
    l10n.onboardingHowDidIGetHere,
    l10n.onboardingHowDoesItWork,
    l10n.onboardingDropHint,
    l10n.onboardingWhatHappensToFile,
    l10n.onboardingFileStaysLocal,
    l10n.onboardingHashExplainer,
    l10n.onboardingSeeYouInTheComments,
  ];
  final List<Remark> dummy = Remark.dummyData;
  final int count = dummy.length < localizedTexts.length
      ? dummy.length
      : localizedTexts.length;
  return List<Remark>.generate(
    count,
    (final int i) =>
        Remark(localizedTexts[i], dummy[i].author, dummy[i].timestamp),
  );
}

class RemarkList extends StatelessWidget {
  const RemarkList({
    super.key,
    required this.remarks,
    required this.userId,
    required this.onDeleteRemark,
    this.emptyMessage,
  });
  final List<Remark>? remarks;
  final String? userId;
  final void Function(Remark) onDeleteRemark;

  /// Shown as a tile when [remarks] holds no entries — the caller passes
  /// `l10n.noRemarksYet` for a real artifact so an empty thread is a visible
  /// state, not a blank void (WCAG 3.3.1-style status availability).
  final String? emptyMessage;

  @override
  Widget build(final BuildContext context) {
    final List<Remark> items = remarks ?? const <Remark>[];
    final bool showEmptyMessage =
        items.isEmpty && (emptyMessage?.isNotEmpty ?? false);
    // Layout: [optional empty-state tile] + remarks + bottom reserve spacer.
    final int firstSpacerIndex = items.length + (showEmptyMessage ? 1 : 0);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (final BuildContext context, final int index) {
          if (showEmptyMessage && index == 0) {
            return ListTile(
              enabled: false,
              title: Text(
                emptyMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          if (index == firstSpacerIndex) {
            return const SizedBox(height: _kBottomReserveHeight);
          }
          final Remark remark = items[index];
          return RemarkWidget(
            remark: remark,
            currentUser: userId ?? '',
            onDeleteRemark: onDeleteRemark,
          );
        },
        childCount: firstSpacerIndex + 1,
      ),
    );
  }
}
