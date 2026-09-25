import 'package:Lore/remark.dart';
import 'package:Lore/remark_widget.dart';
import 'package:flutter/material.dart';

class RemarkList extends StatelessWidget {
  const RemarkList({
    super.key,
    required this.remarks,
    required this.userId,
    required this.onDeleteRemark,
  });
  final List<Remark>? remarks;
  final String? userId;
  final void Function(Remark) onDeleteRemark;

  @override
  Widget build(final BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (final BuildContext context, final int index) {
          if (remarks == null || index == (remarks?.length ?? 0)) {
            return const SizedBox(height: 80);
          }
          final Remark remark = remarks![index];
          return RemarkWidget(
            remark: remark,
            currentUser: userId ?? '',
            onDeleteRemark: onDeleteRemark,
          );
        },
        childCount: (remarks?.length ?? 0) + 1,
      ),
    );
  }
}
