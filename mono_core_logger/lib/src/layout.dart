/// Region and layout hints for renderers.

typedef RegionId = String;

enum LayoutHint {
  overlay,
  pinnedBelow,
  pinnedAbove,
}

class PinnedRegion {
  final RegionId id;
  final String? title;
  const PinnedRegion(this.id, {this.title});
}

class OverlayRegion {
  final RegionId id;
  const OverlayRegion(this.id);
}
