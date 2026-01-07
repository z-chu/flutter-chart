import 'dart:ui';

/// Abstract class for painting vertical barrier labels.
///
/// Implement this class to create custom label painters for vertical barriers.
abstract class VerticalBarrierLabelPainter {
  /// Paints the label on the canvas.
  ///
  /// [canvas] - The canvas to paint on.
  /// [anchor] - The anchor position (calculated based on labelPosition).
  void paint(Canvas canvas, Offset anchor);

  /// Returns the size of the label.
  ///
  /// Used for position calculations.
  Size get size;
}
