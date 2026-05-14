import 'package:deriv_chart/src/models/tick.dart';
import 'package:flutter/widgets.dart';

/// Builds the tooltip/details widget shown next to the crosshair.
///
/// Returning a widget here replaces the default `CrosshairDetails`. The widget
/// is rendered inside the same positioning wrapper used by the default
/// implementation, so the builder only needs to describe the box content.
typedef CrosshairBuilder = Widget Function(
  BuildContext context,
  Tick tick,
  int pipSize,
);
