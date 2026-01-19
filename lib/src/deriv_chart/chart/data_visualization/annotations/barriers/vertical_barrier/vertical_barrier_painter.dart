import 'dart:ui';

import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/series_painter.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/animation_info.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/barrier_objects.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/paint_functions/paint_line.dart';
import 'package:deriv_chart/src/deriv_chart/chart/y_axis/y_axis_config.dart';
import 'package:deriv_chart/src/theme/painting_styles/barrier_style.dart';
import 'package:flutter/material.dart';

import '../../../chart_data.dart';
import 'vertical_barrier.dart';
import 'vertical_barrier_label_painter.dart';

/// A class for painting horizontal barriers.
class VerticalBarrierPainter extends SeriesPainter<VerticalBarrier> {
  /// Initializes [series].
  VerticalBarrierPainter(VerticalBarrier series) : super(series);

  @override
  void onPaint({
    required Canvas canvas,
    required Size size,
    required EpochToX epochToX,
    required QuoteToY quoteToY,
    required AnimationInfo animationInfo,
  }) {
    if (series.isOnRange) {
      // 使用 yAxisClipping 包裹绘制逻辑，防止绘制到 Y 轴标签区域
      YAxisConfig.instance.yAxisClipping(canvas, size, () {
        _paintVerticalBarrier(
          canvas,
          size,
          epochToX,
          quoteToY,
          animationInfo,
        );
      });
    }
  }

  void _paintVerticalBarrier(
    Canvas canvas,
    Size size,
    EpochToX epochToX,
    QuoteToY quoteToY,
    AnimationInfo animationInfo,
  ) {
    final VerticalBarrierStyle style =
        series.style as VerticalBarrierStyle? ?? theme.verticalBarrierStyle;

    final Paint paint = Paint()
      ..color = style.color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    int? animatedEpoch;
    double lineStartY = 0;
    double? dotY;

    if (series.previousObject == null) {
      animatedEpoch = series.epoch;
      if (series.quote != null) {
        dotY = quoteToY(series.quote!);
      }
    } else {
      final VerticalBarrierObject prevObject =
          series.previousObject as VerticalBarrierObject;
      animatedEpoch = lerpDouble(prevObject.epoch.toDouble(), series.epoch,
              animationInfo.currentTickPercent)!
          .toInt();

      if (series.annotationObject.quote != null && prevObject.quote != null) {
        dotY = quoteToY(lerpDouble(prevObject.quote,
            series.annotationObject.quote, animationInfo.currentTickPercent)!);
      }
    }

    final double lineX = epochToX(animatedEpoch!);
    final double lineEndY = size.height;

    if (dotY != null && !series.longLine) {
      lineStartY = dotY;
    }

    if (style.isDashed) {
      paintVerticalDashedLine(
          canvas, lineX, lineStartY, lineEndY, style.color, 1);
    } else {
      canvas.drawLine(
          Offset(lineX, lineStartY), Offset(lineX, lineEndY), paint);
    }

    _paintLineLabel(canvas, lineX, lineStartY, lineEndY, style);
  }

  void _paintLineLabel(
    Canvas canvas,
    double lineX,
    double lineStartY,
    double lineEndY,
    VerticalBarrierStyle style,
  ) {
    // Use custom label painter if provided
    if (style.customLabelPainter != null) {
      _paintCustomLabel(canvas, lineX, lineStartY, lineEndY,
          style.customLabelPainter!, style.labelPosition);
      return;
    }

    // Default single-line label painting
    final TextPainter titlePainter = TextPainter(
      text: TextSpan(
        text: series.title,
        style: style.textStyle,
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final Offset position = _calculateLabelPosition(
      lineX: lineX,
      lineStartY: lineStartY,
      lineEndY: lineEndY,
      labelWidth: titlePainter.width,
      labelHeight: titlePainter.height,
      labelPosition: style.labelPosition,
    );

    titlePainter.paint(canvas, position);
  }

  void _paintCustomLabel(
    Canvas canvas,
    double lineX,
    double lineStartY,
    double lineEndY,
    VerticalBarrierLabelPainter labelPainter,
    VerticalBarrierLabelPosition labelPosition,
  ) {
    final Size labelSize = labelPainter.size;

    final Offset position = _calculateLabelPosition(
      lineX: lineX,
      lineStartY: lineStartY,
      lineEndY: lineEndY,
      labelWidth: labelSize.width,
      labelHeight: labelSize.height,
      labelPosition: labelPosition,
    );

    labelPainter.paint(canvas, position);
  }

  Offset _calculateLabelPosition({
    required double lineX,
    required double lineStartY,
    required double lineEndY,
    required double labelWidth,
    required double labelHeight,
    required VerticalBarrierLabelPosition labelPosition,
  }) {
    late double labelStartX;
    late double labelStartY;

    switch (labelPosition) {
      case VerticalBarrierLabelPosition.auto:
        // Right if there is no space on left, otherwise left. (bottom aligned)
        labelStartX = lineX - labelWidth - 5;
        if (labelStartX < 0) {
          labelStartX = lineX + 5;
        }
        labelStartY = lineEndY - labelHeight;
        break;
      case VerticalBarrierLabelPosition.rightTop:
        labelStartX = lineX + 5;
        labelStartY = lineStartY;
        break;
      case VerticalBarrierLabelPosition.rightBottom:
        labelStartX = lineX + 5;
        labelStartY = lineEndY - labelHeight;
        break;
      case VerticalBarrierLabelPosition.leftTop:
        labelStartX = lineX - labelWidth - 5;
        labelStartY = lineStartY;
        break;
      case VerticalBarrierLabelPosition.leftBottom:
        labelStartX = lineX - labelWidth - 5;
        labelStartY = lineEndY - labelHeight;
        break;
    }

    return Offset(labelStartX, labelStartY);
  }
}
