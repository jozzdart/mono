import '../style/theme.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// MiniMap – ASCII representation of document position.
///
/// Beautiful, theme-aware miniature overview map that aligns with ThemeDemo
/// styling. Shows the current viewport within a total document length.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// MiniMap(totalLines: 1200, viewportStart: 300, viewportSize: 48)
///   .withPastelTheme()
///   .show();
/// ```
///
/// Usage:
///   MiniMap(
///     totalLines: 1200,
///     viewportStart: 300,
///     viewportSize: 48,
///   ).withPastelTheme().show();
class MiniMap with Themeable {
  final int totalLines;
  final int viewportStart; // 0-based index of first visible line
  final int viewportSize; // count of visible lines
  final int height; // visual map height in rows
  final int width; // visual width of the map area (characters)
  @override
  final PromptTheme theme;
  final String? label;
  final List<int> markers; // optional significant line indices

  MiniMap({
    required this.totalLines,
    required this.viewportStart,
    required this.viewportSize,
    this.height = 24,
    this.width = 14,
    this.theme = PromptTheme.dark,
    this.label,
    List<int>? markers,
  })  : assert(totalLines > 0),
        assert(viewportStart >= 0),
        assert(viewportSize >= 0),
        assert(height >= 6),
        assert(width >= 6),
        markers = markers ?? const [];

  @override
  MiniMap copyWithTheme(PromptTheme theme) {
    return MiniMap(
      totalLines: totalLines,
      viewportStart: viewportStart,
      viewportSize: viewportSize,
      height: height,
      width: width,
      theme: theme,
      label: label,
      markers: markers,
    );
  }

  void show() {
    final title = (label == null || label!.isEmpty) ? 'Mini Map' : label!;
    final frame = WidgetFrame(title: title, theme: theme);
    frame.show(_renderContent);
  }

  /// Renders to the given [RenderOutput] for external line tracking.
  /// Use this when animating or updating the widget repeatedly.
  void showTo(RenderOutput out) {
    final title = (label == null || label!.isEmpty) ? 'Mini Map' : label!;
    final frame = WidgetFrame(title: title, theme: theme);
    frame.showTo(out, _renderContent);
  }

  void _renderContent(FrameContext ctx) {
    // Render the map area
    for (int row = 0; row < height; row++) {
      ctx.gutterLine(_rowChunk(row));
    }

    // Metrics line beneath the map
    final percentTop = _percent(viewportStart, totalLines);
    final percentBottom = _percent(viewportStart + viewportSize, totalLines);
    final metrics = StringBuffer();
    metrics.write(
        '${theme.dim}Lines:${theme.reset} ${theme.accent}${_padInt(totalLines)}${theme.reset}   ');
    metrics.write(
        '${theme.dim}View:${theme.reset} ${theme.selection}${_padInt(viewportStart + 1)}${theme.reset}-${theme.selection}${_padInt((viewportStart + viewportSize).clamp(1, totalLines))}${theme.reset}   ');
    metrics.write(
        '${theme.dim}Pos:${theme.reset} ${theme.info}$percentTop%${theme.reset}-${theme.info}$percentBottom%${theme.reset}');
    ctx.gutterLine(metrics.toString());
  }

  String _rowChunk(int row) {
    // Map each visual row to a range of document lines.
    // We use inclusive lower, exclusive upper indices.
    final linesPerRow = totalLines / height;
    final startLine = (row * linesPerRow).floor();
    final endLine = (((row + 1) * linesPerRow).ceil()).clamp(1, totalLines);

    // Determine overlap with viewport
    final viewStart = viewportStart;
    final viewEnd = (viewportStart + viewportSize).clamp(0, totalLines);
    final overlaps = (endLine > viewStart) && (startLine < viewEnd);

    // Count markers in this segment
    final markerCount =
        markers.where((m) => m >= startLine && m < endLine).length;

    // Build a horizontal micro-bar to represent density + viewport
    final buf = StringBuffer();
    final barInner = width - 2; // two edges
    final leftEdge = '▏';
    final rightEdge = '▕';

    buf.write('${theme.gray}$leftEdge${theme.reset}');

    if (barInner <= 0) return buf.toString();

    // Base density fill
    // Use light shade for base, accent/highlight when in viewport, and dots for markers.
    for (int i = 0; i < barInner; i++) {
      final isViewport = overlaps;
      final hasMarker = markerCount > 0 &&
          (i % (barInner ~/ (markerCount.clamp(1, barInner))) == 0);

      if (hasMarker && isViewport) {
        buf.write('${theme.inverse}${theme.highlight}●${theme.reset}');
      } else if (hasMarker) {
        buf.write('${theme.warn}•${theme.reset}');
      } else if (isViewport) {
        buf.write('${theme.accent}▓${theme.reset}');
      } else {
        buf.write('${theme.dim}░${theme.reset}');
      }
    }

    buf.write('${theme.gray}$rightEdge${theme.reset}');
    return buf.toString();
  }

  int _percent(int value, int total) {
    if (total <= 0) return 0;
    final v = (value * 100 / total).clamp(0, 100).round();
    return v;
  }

  String _padInt(int n) {
    final s = n.toString();
    if (s.length >= 4) return s;
    return s.padLeft(4, ' ');
  }
}
