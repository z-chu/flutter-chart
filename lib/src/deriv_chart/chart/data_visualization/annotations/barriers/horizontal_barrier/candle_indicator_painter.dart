import 'dart:math';
import 'dart:ui';

import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_data.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/animation_info.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/barrier_objects.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/functions/helper_functions.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/paint_functions/paint_dot.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/paint_functions/paint_line.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/paint_functions/paint_text.dart';
import 'package:deriv_chart/src/deriv_chart/chart/y_axis/y_axis_config.dart';
import 'package:deriv_chart/src/theme/painting_styles/barrier_style.dart';
import 'package:flutter/material.dart';

import 'horizontal_barrier.dart';
import 'horizontal_barrier_painter.dart';
import 'tick_indicator.dart';

/// A class for painting candle indicators.
/// 当 showTimer 为 true 时，价格和计时器会合并在一个统一的圆角矩形容器内显示。
class CandleIndicatorPainter extends HorizontalBarrierPainter<CandleIndicator> {
  /// Initializes [series].
  CandleIndicatorPainter(
    CandleIndicator series,
  ) : super(series);

  late Paint _paint;

  /// Padding between lines.
  static const double padding = 8;

  @override
  void onPaint({
    required Canvas canvas,
    required Size size,
    required EpochToX epochToX,
    required QuoteToY quoteToY,
    required AnimationInfo animationInfo,
  }) {
    if (!series.isOnRange) {
      return;
    }

    // 如果显示计时器，则自己绘制合并的标签，不调用父类的标签绘制
    if (series.showTimer) {
      _paintCombinedLabel(
        canvas,
        size,
        epochToX,
        quoteToY,
        animationInfo,
      );
    } else {
      // 不显示计时器时，使用父类的默认绘制
      super.onPaint(
        canvas: canvas,
        size: size,
        epochToX: epochToX,
        quoteToY: quoteToY,
        animationInfo: animationInfo,
      );
    }
  }

  /// 绘制合并的标签（价格 + 计时器在同一个圆角矩形内）
  void _paintCombinedLabel(
    Canvas canvas,
    Size size,
    EpochToX epochToX,
    QuoteToY quoteToY,
    AnimationInfo animationInfo,
  ) {
    final HorizontalBarrierStyle style =
        series.style as HorizontalBarrierStyle? ?? theme.horizontalBarrierStyle;

    _paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1
      ..color = style.color;

    late double animatedValue;
    double? dotX;

    // If previous object is null then its first load and no need to perform
    // transition animation from previousObject to new object.
    if (series.previousObject == null) {
      animatedValue = series.quote!;
      if (series.epoch != null) {
        dotX = epochToX(series.epoch!);
      }
    } else {
      final BarrierObject previousBarrier = series.previousObject!;
      // Calculating animated values regarding `currentTickPercent` in
      // transition animation from previousObject to new object
      animatedValue = lerpDouble(
        previousBarrier.quote!,
        series.quote!,
        animationInfo.currentTickPercent,
      )!;

      if (series.epoch != null && series.previousObject!.leftEpoch != null) {
        dotX = lerpDouble(
          epochToX(series.previousObject!.leftEpoch!),
          epochToX(series.epoch!),
          animationInfo.currentTickPercent,
        );
      }
    }

    double y = quoteToY(animatedValue);

    // 计算合并后的总高度（两行）
    final double combinedHeight = style.labelHeight * 2;
    // 价格行高度的一半
    final double priceRowHalfHeight = style.labelHeight / 2;

    if (series.visibility ==
        HorizontalBarrierVisibility.keepBarrierLabelVisible) {
      // 容器顶部 = y - priceRowHalfHeight
      // 容器底部 = y - priceRowHalfHeight + combinedHeight = y + priceRowHalfHeight + style.labelHeight
      // 需要确保整个容器在屏幕内
      final double containerTop = y - priceRowHalfHeight;
      final double containerBottom = y + priceRowHalfHeight + style.labelHeight;

      if (containerTop < 0) {
        y = priceRowHalfHeight;
      } else if (containerBottom > size.height) {
        y = size.height - priceRowHalfHeight - style.labelHeight;
      }
    }

    // 绘制闪烁点
    if (style.hasBlinkingDot && dotX != null) {
      YAxisConfig.instance.yAxisClipping(canvas, size, () {
        paintBlinkingDot(
            canvas, dotX!, y, animationInfo, style.blinkingDotColor);
      });
    }

    // 准备文本
    final TextPainter valuePainter = makeTextPainter(
      animatedValue.toStringAsFixed(chartConfig.pipSize),
      style.textStyle,
    );

    String timerString = '--:--';
    if (series.timerDuration != null) {
      timerString = durationToString(series.timerDuration ?? const Duration());
    }

    // 计时器使用自定义样式，如果没有提供则使用默认的 style.textStyle
    final TextStyle timerTextStyle = series.timerTextStyle ?? style.textStyle;
    final TextPainter timerPainter = makeTextPainter(
      timerString,
      timerTextStyle,
    );

    // 取两者中较宽的作为统一宽度
    final double maxTextWidth =
        max<double>(timerPainter.width, valuePainter.width);
    final double textWidthWithPadding = maxTextWidth + style.labelPadding * 2;

    // 如果设置了 labelWidth，取 labelWidth 和文字宽度的较大值
    final double containerWidth = style.labelWidth != null
        ? max<double>(style.labelWidth!, textWidthWithPadding)
        : textWidthWithPadding;

    // 计算容器位置（右对齐）
    final double containerRight = size.width - style.rightMargin;
    final double containerLeft = containerRight - containerWidth;
    final double containerCenterX = containerLeft + containerWidth / 2;

    // 整个容器的区域
    // 价格行的中心在 y，所以容器顶部在 y - priceRowHalfHeight
    final Rect containerArea = Rect.fromLTWH(
      containerLeft,
      y - priceRowHalfHeight,
      containerWidth,
      combinedHeight,
    );

    // 绘制水平虚线（到容器左边缘）
    if (style.hasLine) {
      final double lineStartX = series.longLine ? 0 : (dotX ?? 0);
      final double lineEndX = containerArea.left;

      if (lineStartX < lineEndX) {
        if (style.isDashed) {
          paintHorizontalDashedLine(
            canvas,
            lineEndX,
            lineStartX,
            y,
            style.lineColor,
            1,
          );
        } else {
          _paint.color = style.lineColor;
          canvas.drawLine(Offset(lineStartX, y), Offset(lineEndX, y), _paint);
        }
      }
    }

    // 绘制统一的圆角矩形背景
    final RRect containerRRect = RRect.fromRectAndRadius(
      containerArea,
      const Radius.circular(4),
    );
    _paint.color = style.color;
    canvas.drawRRect(containerRRect, _paint);

    // 上半部分：价格标签区域（中心就是 y，与水平线对齐）
    final double priceRowCenterY = y;

    // 下半部分：计时器标签区域（带有不同的背景色）
    final double timerRowTop = y + priceRowHalfHeight;
    final double timerRowCenterY = timerRowTop + style.labelHeight / 2;

    // 绘制计时器区域的背景（下半部分，裁切到容器内）
    canvas
      ..save()
      ..clipRRect(containerRRect);

    final Rect timerBgArea = Rect.fromLTRB(
      containerArea.left,
      timerRowTop,
      containerArea.right,
      containerArea.bottom,
    );
    _paint.color = style.secondaryBackgroundColor;
    canvas
      ..drawRect(timerBgArea, _paint)
      ..restore();

    // 绘制价格文本（上半部分）
    paintWithTextPainter(
      canvas,
      painter: valuePainter,
      anchor: Offset(containerCenterX, priceRowCenterY),
    );

    // 绘制计时器文本（下半部分）
    paintWithTextPainter(
      canvas,
      painter: timerPainter,
      anchor: Offset(containerCenterX, timerRowCenterY),
    );
  }
}
