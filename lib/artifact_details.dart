import 'package:Lore/artifact.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';

class ArtifactDetailsWidget extends StatelessWidget {
  const ArtifactDetailsWidget({super.key, this.artifact});

  final Artifact? artifact;

  @override
  Widget build(BuildContext context) {
    final String name = artifact?.name ?? '';
    final String path = artifact?.path ?? '';
    final String md5sum = artifact?.md5sum ?? '';

    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.all(0.0),
      alignment:
          AlignmentGeometry.lerp(Alignment.topCenter, Alignment.center, 0.5),
      child: Row(children: [
        FileIcon(name, size: 180),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "Name: $name",
              style: Theme.of(context).primaryTextTheme.bodyMedium,
            ),
            Text(
              'Path: $path',
              style: Theme.of(context).primaryTextTheme.bodyMedium,
            ),
            Text(
              'md5: $md5sum',
              style: Theme.of(context).primaryTextTheme.bodyMedium,
            )
          ],
        ),
      ]),
    );
  }
}

class ArtifactPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return const Expanded(child: ArtifactDetailsWidget());
  }

  @override
  double get maxExtent => 300.0;

  @override
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class ArtifactSliverScrollViewWidget extends StatelessWidget {
  const ArtifactSliverScrollViewWidget({super.key});

  @override
  Widget build(final BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: ArtifactPersistentHeaderDelegate()),
      ],
    );
  }
}
