import 'package:Lore/artifact.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';

class ArtifactDetailsWidget extends StatelessWidget {
  const ArtifactDetailsWidget({super.key, this.artifact});

  final Artifact? artifact;

  @override
  Widget build(BuildContext context) {
    if (artifact == null) {
      return const Spacer();
    }

    return Container(
        color: Colors.blue,
        padding: const EdgeInsets.all(36.0),
        alignment:
            AlignmentGeometry.lerp(Alignment.topCenter, Alignment.center, 0.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FileIcon('${artifact?.name}', size: 180),
            Text("File name: ${artifact?.name}"),
            Text('File path: ${artifact?.path}'),
            Text('md5: ${artifact?.md5sum}')
          ],
        ));
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
