import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/series_painter.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/barrier_objects.dart';
import 'package:deriv_chart/src/models/tick.dart';
import 'package:deriv_chart/src/theme/painting_styles/barrier_style.dart';

import '../barrier.dart';
import 'vertical_barrier_painter.dart';

/// Vertical barrier visibility behavior and whether it affects the X-axis range.
enum VerticalBarrierVisibility {
  /// Normal behavior - barrier may be off-screen if it's outside the current
  /// visible range. User can manually scroll to see it.
  normal,

  /// Will try to zoom out the X-axis to make this barrier visible.
  /// If the barrier is too far and cannot be shown even at maximum zoom-out,
  /// it won't force the zoom and user can manually scroll to see it.
  fitIfPossible,
}

/// Vertical barrier class.
class VerticalBarrier extends Barrier {
  /// Initializes a vertical barrier class.
  VerticalBarrier(
    int epoch, {
    double? quote,
    String? id,
    String? title,
    BarrierStyle? style,
    bool longLine = true,
    this.visibility = VerticalBarrierVisibility.normal,
  }) : super(
          id: id,
          title: title,
          epoch: epoch,
          quote: quote,
          style: style,
          longLine: longLine,
        );

  /// Barrier visibility behavior.
  final VerticalBarrierVisibility visibility;

  /// A vertical barrier on [Tick]'s epoch.
  factory VerticalBarrier.onTick(
    Tick tick, {
    String? id,
    String? title,
    BarrierStyle? style,
    bool longLine = true,
    VerticalBarrierVisibility visibility = VerticalBarrierVisibility.normal,
  }) =>
      VerticalBarrier(
        tick.epoch,
        quote: tick.quote,
        id: id,
        title: title,
        style: style,
        longLine: longLine,
        visibility: visibility,
      );

  @override
  SeriesPainter<Series> createPainter() => VerticalBarrierPainter(this);

  @override
  BarrierObject createObject() => VerticalBarrierObject(epoch!, quote: quote);

  // Force repaint to ensure vertical barrier gets cleared when out of range.
  // Safe since onPaint() in [VerticalBarrierPainter] checks
  // series.isOnRange before drawing.
  @override
  bool shouldRepaint(covariant Barrier previous) {
    return true;
  }

  @override
  List<double> recalculateMinMax() =>
      isOnRange ? super.recalculateMinMax() : <double>[double.nan, double.nan];
}
