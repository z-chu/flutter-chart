import 'dart:math';

import 'package:flutter/material.dart';

import 'label_line.dart';
import 'vertical_barrier_label_painter.dart';

/// A label painter that supports multiple lines with different styles and spacing.
///
/// Example usage:
/// ```dart
/// final labelPainter = MultiLineLabelPainter(
///   lines: [
///     LabelLine(
///       text: 'Settlement Time',
///       style: TextStyle(color: Colors.white, fontSize: 12),
///     ),
///     LabelLine(
///       text: '17:05:00',
///       style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
///       topSpacing: 4,
///     ),
///     LabelLine(
///       text: 'Entry Countdown',
///       style: TextStyle(color: Colors.white, fontSize: 12),
///       topSpacing: 16,
///     ),
///     LabelLine(
///       text: '01:27',
///       style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
///       topSpacing: 4,
///     ),
///   ],
/// );
/// ```
class MultiLineLabelPainter implements VerticalBarrierLabelPainter {
  /// Creates a multi-line label painter.
  ///
  /// [lines] - The list of label lines to paint.
  MultiLineLabelPainter({
    required this.lines,
  }) {
    _initializePainters();
  }

  /// The list of label lines to paint.
  final List<LabelLine> lines;

  late Size _size;
  final List<TextPainter> _painters = <TextPainter>[];

  void _initializePainters() {
    double totalHeight = 0;
    double maxWidth = 0;

    for (int i = 0; i < lines.length; i++) {
      final LabelLine line = lines[i];
      final TextPainter painter = TextPainter(
        text: TextSpan(text: line.text, style: line.style),
        textDirection: TextDirection.ltr,
      )..layout();

      _painters.add(painter);

      // Add top spacing (except for the first line)
      if (i > 0) {
        totalHeight += line.topSpacing;
      }
      totalHeight += painter.height;
      maxWidth = max(maxWidth, painter.width);
    }

    _size = Size(maxWidth, totalHeight);
  }

  @override
  Size get size => _size;

  @override
  void paint(Canvas canvas, Offset anchor) {
    double currentY = anchor.dy;

    for (int i = 0; i < lines.length; i++) {
      final LabelLine line = lines[i];
      final TextPainter painter = _painters[i];

      // Add top spacing (except for the first line)
      if (i > 0) {
        currentY += line.topSpacing;
      }

      painter.paint(canvas, Offset(anchor.dx, currentY));
      currentY += painter.height;
    }
  }
}
