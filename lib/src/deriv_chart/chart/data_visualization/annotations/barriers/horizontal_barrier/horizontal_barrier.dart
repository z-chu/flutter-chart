import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/series_painter.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/barrier_objects.dart';
import 'package:deriv_chart/src/theme/painting_styles/barrier_style.dart';

import '../barrier.dart';
import 'horizontal_barrier_painter.dart';

/// Horizontal barrier class.
class HorizontalBarrier extends Barrier {
  /// Initializes a horizontal barrier.
  HorizontalBarrier(
    double quote, {
    int? epoch,
    String? id,
    String? title,
    bool longLine = true,
    HorizontalBarrierStyle? style,
    this.visibility = HorizontalBarrierVisibility.keepBarrierLabelVisible,
    this.hidden = false,
    this.avoidLabelOverlapWithQuote,
  }) : super(
          id: id,
          title: title,
          epoch: epoch,
          quote: quote,
          style: style,
          longLine: longLine,
        );

  /// Barrier visibility behavior.
  final HorizontalBarrierVisibility visibility;

  /// When `true`, the barrier is not painted (no line, label, dot, title, or
  /// arrow), but still participates in Y-Axis range calculation when
  /// [visibility] is [HorizontalBarrierVisibility.forceToStayOnRange].
  ///
  /// Useful as a pure "Y-axis anchor" so that external quotes (e.g. an opened
  /// position's entry price rendered as a marker) can force the chart to keep
  /// them inside the visible Y range without drawing an extra line.
  final bool hidden;

  /// 当本 barrier 的 label 会与另一条画在 [avoidLabelOverlapWithQuote] 价位的
  /// barrier label 在 Y 轴上重叠时，把**本 barrier 的 label（标题 + 数字）** 沿
  /// Y 轴推开，让两个 label 都可读（另一条 barrier 保持原位，本 barrier 让位）。
  ///
  /// 推开方向按价格大小：本 barrier 价 ≥ 对方 → label 显示在对方**上方**，否则下方
  /// （相等时也走上方）。纯视觉调整——只挪 label，参考线 / 脉冲点仍画在真实价位。
  /// 为 null 时不做任何避让（默认行为不变）。
  ///
  /// 典型用法：当前价 / Final 线设为 P2B 价，让它们给固定的 P2B 让位。
  final double? avoidLabelOverlapWithQuote;

  @override
  SeriesPainter<Series> createPainter() =>
      HorizontalBarrierPainter<HorizontalBarrier>(this);

  @override
  List<double> recalculateMinMax() =>
      // When its visibility is NOT forceToStayOnRange, we return [NaN, NaN],
      // so the chart will ignore this barrier when it wants to define
      // its Y-Axis range.
      visibility == HorizontalBarrierVisibility.forceToStayOnRange
          ? super.recalculateMinMax()
          : <double>[double.nan, double.nan];

  @override
  BarrierObject createObject() => BarrierObject(leftEpoch: epoch, quote: quote);
}

/// Horizontal barrier visibility behavior and whether it contributes in
/// defining the overall Y-Axis range of the chart.
enum HorizontalBarrierVisibility {
  /// Won't force the chart to keep the barrier in its Y-Axis range, if it was
  /// out of range it will go off the screen.
  normal,

  /// Won't force the chart to keep the barrier in its Y-Axis range, if it was
  /// out of range, will show it on top/bottom edge with an arrow which indicates
  /// its value is beyond Y-Axis range.
  keepBarrierLabelVisible,

  /// Will forces the chart to keep this barrier in its Y-Axis range.
  forceToStayOnRange,
}
