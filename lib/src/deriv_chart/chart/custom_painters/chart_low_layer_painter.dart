import 'dart:math' as math;
import 'dart:ui';

import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/animation_info.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/paint_functions/paint_line.dart';
import 'package:deriv_chart/src/deriv_chart/chart/y_axis/y_axis_config.dart';
import 'package:deriv_chart/src/models/chart_low_layer_config.dart';

/// 磨砂背景绘制器
class ChartLowLayerPainter {
  /// 绘制磨砂背景
  static void paint({
    required Canvas canvas,
    required Size size,
    required ChartLowLayerConfig config,
    required double Function(int) epochToCanvasX,
    required Color defaultBackgroundColor,
    required double topY,
    required double bottomY,
    AnimationInfo animationInfo = const AnimationInfo(),
  }) {
    // 使用 yAxisClipping 包裹绘制逻辑，防止绘制到 Y 轴标签区域
    YAxisConfig.instance.yAxisClipping(canvas, size, () {
      _paintLowLayer(
        canvas: canvas,
        size: size,
        config: config,
        epochToCanvasX: epochToCanvasX,
        defaultBackgroundColor: defaultBackgroundColor,
        topY: topY,
        bottomY: bottomY,
        animationInfo: animationInfo,
      );
    });
  }

  static void _paintLowLayer({
    required Canvas canvas,
    required Size size,
    required ChartLowLayerConfig config,
    required double Function(int) epochToCanvasX,
    required Color defaultBackgroundColor,
    required double topY,
    required double bottomY,
    required AnimationInfo animationInfo,
  }) {
    // 计算动画后的 epoch 值
    int animatedStartEpoch = config.startEpoch;
    int animatedEndEpoch = config.endEpoch;

    final ChartLowLayerConfig? previousConfig = config.previousConfig;
    if (previousConfig != null) {
      // 使用 lerpDouble 进行插值动画
      animatedStartEpoch = lerpDouble(
            previousConfig.startEpoch.toDouble(),
            config.startEpoch.toDouble(),
            animationInfo.currentTickPercent,
          )?.toInt() ??
          config.startEpoch;

      animatedEndEpoch = lerpDouble(
            previousConfig.endEpoch.toDouble(),
            config.endEpoch.toDouble(),
            animationInfo.currentTickPercent,
          )?.toInt() ??
          config.endEpoch;
    }

    // 计算背景区域的 X 坐标（使用动画后的值）
    final double startX = epochToCanvasX(animatedStartEpoch);
    final double endX = epochToCanvasX(animatedEndEpoch);

    // 确保区域在可见范围内
    if (endX < 0 || startX > size.width) {
      return; // 区域不在可见范围内
    }

    // 计算实际绘制区域
    final double left = startX.clamp(0.0, size.width);
    final double right = endX.clamp(0.0, size.width);
    final double top = topY;
    final double bottom = bottomY;

    if (right <= left) {
      return; // 无效区域
    }

    // 创建绘制区域
    final Rect backgroundRect = Rect.fromLTRB(left, top, right, bottom);

    // 确定背景颜色
    final Color? bgColor = config.backgroundColor;
    if (bgColor != null) {
      // 绘制半透明背景
      final Paint backgroundPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(backgroundRect, backgroundPaint);
    }

    // 绘制斜线图案
    _drawDiagonalPattern(
      canvas: canvas,
      rect: backgroundRect,
      config: config,
      defaultBackgroundColor: defaultBackgroundColor,
    );

    // 绘制开始和结束时间的竖线（使用动画后的 epoch 值）
    _drawVerticalLines(
      canvas: canvas,
      size: size,
      config: config,
      startX: startX,
      endX: endX,
      topY: topY,
      bottomY: bottomY,
    );
  }

  /// 绘制斜线图案
  static void _drawDiagonalPattern({
    required Canvas canvas,
    required Rect rect,
    required ChartLowLayerConfig config,
    required Color defaultBackgroundColor,
  }) {
    if (rect.width == 0 || rect.height == 0 || rect.width < 2) {
      return;
    }
    // 检查是否有图案配置
    final LowLayerPatternConfig? patternConfig = config.patternConfig;
    if (patternConfig == null) {
      return;
    }

    // 将角度转换为弧度
    final double angleRad = patternConfig.patternAngle * (math.pi / 180.0);

    // 计算斜线的方向向量
    final double cosAngle = math.cos(angleRad);
    final double sinAngle = math.sin(angleRad);

    // 计算图案间距在 X 和 Y 方向的分量
    final double spacingX = patternConfig.patternSpacing * cosAngle.abs();
    final double spacingY = patternConfig.patternSpacing * sinAngle.abs();

    // 创建图案画笔
    final Paint patternPaint = Paint()
      ..color = patternConfig.patternColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 保存画布状态
    canvas.save();

    // 裁剪到背景区域
    canvas.clipRect(rect);

    // 计算需要绘制的斜线范围
    final double rectWidth = rect.width;
    final double rectHeight = rect.height;
    final double diagonalLength =
        math.sqrt(rectWidth * rectWidth + rectHeight * rectHeight);

    // 计算起始点（从左上角开始）
    final double startX = rect.left;
    final double startY = rect.top;

    // 绘制斜线图案
    final int lineCount =
        (diagonalLength / patternConfig.patternSpacing).ceil() + 2;
    for (int i = -lineCount; i <= lineCount; i++) {
      // 计算当前线的起点和终点
      final double offsetX = i * spacingX;
      final double offsetY = i * spacingY;

      // 计算线的起点（从矩形边界外开始，确保覆盖整个区域）
      final double lineStartX = startX + offsetX - diagonalLength * cosAngle;
      final double lineStartY = startY + offsetY - diagonalLength * sinAngle;

      // 计算线的终点
      final double lineEndX = lineStartX + diagonalLength * 2 * cosAngle;
      final double lineEndY = lineStartY + diagonalLength * 2 * sinAngle;

      // 绘制斜线
      canvas.drawLine(
        Offset(lineStartX, lineStartY),
        Offset(lineEndX, lineEndY),
        patternPaint,
      );
    }

    // 恢复画布状态
    canvas.restore();
  }

  /// 绘制开始和结束时间的竖线
  static void _drawVerticalLines({
    required Canvas canvas,
    required Size size,
    required ChartLowLayerConfig config,
    required double startX,
    required double endX,
    required double topY,
    required double bottomY,
  }) {
    // 绘制开始时间的竖线
    if (config.startLineConfig != null) {
      if (startX >= 0 && startX <= size.width) {
        _drawVerticalLine(
          canvas: canvas,
          x: startX,
          topY: topY,
          bottomY: bottomY,
          lineConfig: config.startLineConfig!,
        );
      }
    }

    // 绘制结束时间的竖线
    if (config.endLineConfig != null) {
      //如果结束时间与开始时间相同，则不绘制结束时间的竖线
      if (endX == startX && config.startLineConfig != null) {
        return;
      }
      if (endX >= 0 && endX <= size.width) {
        _drawVerticalLine(
          canvas: canvas,
          x: endX,
          topY: topY,
          bottomY: bottomY,
          lineConfig: config.endLineConfig!,
        );
      }
    }
  }

  /// 绘制单条竖线
  static void _drawVerticalLine({
    required Canvas canvas,
    required double x,
    required double topY,
    required double bottomY,
    required LowLayerLineConfig lineConfig,
  }) {
    if (lineConfig.isDashed) {
      // 虚线模式：使用 paintVerticalDashedLine
      paintVerticalDashedLine(
        canvas,
        x,
        topY,
        bottomY,
        lineConfig.color,
        lineConfig.strokeWidth,
        dashWidth: lineConfig.dashWidth,
        dashSpace: lineConfig.dashSpace,
      );
    } else {
      // 实线模式：直接绘制
      final Paint linePaint = Paint()
        ..color = lineConfig.color
        ..strokeWidth = lineConfig.strokeWidth
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, topY),
        Offset(x, bottomY),
        linePaint,
      );
    }
  }
}
