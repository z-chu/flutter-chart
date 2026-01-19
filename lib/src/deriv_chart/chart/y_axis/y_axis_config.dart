import 'package:flutter/material.dart';

// TODO(NA): Change to a non-singleton class in the future, since it can be an
// anti-pattern in some cases, and usually leads to tight coupling in the
// codebase.
///Singleton class to manage configuration and operations related to the Y-axis
///in custom painting
class YAxisConfig {
  //Private constructor to prevent external instantiation.
  YAxisConfig._();

  static final YAxisConfig _instance = YAxisConfig._();

  /// The single instance of `YAxisConfig`.
  static YAxisConfig get instance => _instance;

  ///Cached width of the label on the Y-axis. This is nullable to handle cases
  ///where it might not be set yet.
  double? cachedLabelWidth;

  /// Whether to enable Y-axis clipping. When false, chart data can be drawn
  /// over the Y-axis labels area.
  bool enableClipping = true;

  ///Sets and caches the label width for the Y-axis. Returns the set width for
  ///potential immediate use.
  double setLabelWidth(double width) {
    cachedLabelWidth = width;
    return cachedLabelWidth!;
  }

  ///Executes painting logic within a clipped area of the canvas to prevent
  ///drawing over the Y-axis labels.
  void yAxisClipping(Canvas canvas, Size size, VoidCallback paintingLogic) {
    if (enableClipping) {
      final Rect clipRect = Rect.fromLTWH(
        0,
        0,
        size.width - (cachedLabelWidth ?? 0),
        size.height,
      );
      canvas
        ..save()
        ..clipRect(clipRect);
      paintingLogic();
      canvas.restore();
    } else {
      // 不裁剪，直接执行绘制逻辑
      paintingLogic();
    }
  }
}
