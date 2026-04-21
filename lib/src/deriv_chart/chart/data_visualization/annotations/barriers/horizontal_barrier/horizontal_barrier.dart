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
