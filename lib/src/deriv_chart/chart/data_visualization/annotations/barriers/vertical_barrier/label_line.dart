import 'package:flutter/material.dart';

/// Configuration for a single line in a multi-line label.
class LabelLine {
  /// Creates a label line configuration.
  ///
  /// [text] - The text content of this line.
  /// [style] - The text style for this line.
  /// [topSpacing] - The spacing above this line (from the previous line).
  const LabelLine({
    required this.text,
    required this.style,
    this.topSpacing = 0,
  });

  /// The text content of this line.
  final String text;

  /// The text style for this line.
  final TextStyle style;

  /// The spacing above this line (from the previous line).
  ///
  /// This is ignored for the first line.
  final double topSpacing;
}

