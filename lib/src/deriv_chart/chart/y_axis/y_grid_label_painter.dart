import 'package:deriv_chart/src/deriv_chart/chart/helpers/paint_functions/paint_text.dart';
import 'package:deriv_chart/src/theme/painting_styles/grid_style.dart';
import 'package:flutter/material.dart';

/// A class that paints a lable on the Y axis of grid.
class YGridLabelPainter extends CustomPainter {
  /// initializes a class that paints a lable on the Y axis of grid.
  YGridLabelPainter({
    required this.gridLineQuotes,
    required this.pipSize,
    required this.quoteToCanvasY,
    required this.style,
    this.quoteLabelFormatter,
  });

  /// Number of digits after decimal point in price.
  final int pipSize;

  /// The list of quotes.
  final List<double> gridLineQuotes;

  /// Conversion function for converting quote to chart's canvas' Y position.
  final double Function(double) quoteToCanvasY;

  /// The style of chart's grid.

  final GridStyle style;

  /// 可选：把 quote 值格式化成 Y 轴 label 文本（如概率 0–1 映射为 '48%'）。
  /// null 时回退到 quote.toStringAsFixed(pipSize) 的默认数字格式。
  final String Function(double)? quoteLabelFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    for (final double quote in gridLineQuotes) {
      final double y = quoteToCanvasY(quote);

      paintText(
        canvas,
        text: quoteLabelFormatter?.call(quote) ?? quote.toStringAsFixed(pipSize),
        style: style.yLabelStyle,
        anchor: Offset(size.width - style.labelHorizontalPadding, y),
        anchorAlignment: Alignment.centerRight,
      );
    }
  }

  @override
  bool shouldRepaint(YGridLabelPainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(YGridLabelPainter oldDelegate) => false;
}
