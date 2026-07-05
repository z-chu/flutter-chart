import 'package:flutter/foundation.dart';

/// Default top bound quote.
const double defaultTopBoundQuote = 60;

/// Default bottom bound quote.
const double defaultBottomBoundQuote = 30;

/// Default Max distance between [rightBoundEpoch] and [_nowEpoch] in pixels.
/// Limits panning to the right.
const double defaultMaxCurrentTickOffset = 150;

/// Configuration for the chart axis.
@immutable
class ChartAxisConfig {
  /// Initializes the chart axis configuration.
  const ChartAxisConfig({
    this.initialTopBoundQuote = defaultTopBoundQuote,
    this.initialBottomBoundQuote = defaultBottomBoundQuote,
    this.maxCurrentTickOffset = defaultMaxCurrentTickOffset,
    this.initialCurrentTickOffset,
    this.defaultIntervalWidth = 20,
    this.showQuoteGrid = true,
    this.showEpochGrid = true,
    this.showFrame = false,
    this.smoothScrolling = true,
    this.rollingWindowData = false,
  });

  /// Top quote bound target for animated transition.
  final double initialTopBoundQuote;

  /// Bottom quote bound target for animated transition.
  final double initialBottomBoundQuote;

  /// Max distance between [rightBoundEpoch] and [_nowEpoch] in pixels.
  /// Limits panning to the right.
  final double maxCurrentTickOffset;

  /// Initial distance between [rightBoundEpoch] and the last tick in pixels.
  /// If null, defaults to [maxCurrentTickOffset].
  final double? initialCurrentTickOffset;

  /// Show Quote Grid lines and labels.
  final bool showQuoteGrid;

  /// Show Epoch Grid lines and labels.
  final bool showEpochGrid;

  /// Show the chart frame and indicators dividers.
  ///
  /// Used in the mobile chart.
  final bool showFrame;

  /// The default distance between two ticks in pixels.
  ///
  /// Default to this interval width on granularity change.
  final double defaultIntervalWidth;

  /// Whether the chart should scroll smoothly.
  /// If `true`, the chart will smoothly adjust the scroll position
  /// (if the last tick is visible) to the right to continuously show new ticks.
  /// If `false`, the chart will only auto-scroll to keep the new tick visible
  /// after receiving a new tick.
  ///
  /// Default is `true`.
  final bool smoothScrolling;

  /// Set to `true` when the chart's data is a fixed-size rolling window that
  /// drops its oldest tick whenever a new one arrives (so the first AND last
  /// entry epoch both change on every update).
  ///
  /// The chart normally auto-scrolls to the live edge when both the first and
  /// last epoch change, treating it as a market/granularity switch. For a
  /// rolling-window feed that heuristic mis-fires on every tick and resets the
  /// view to live ~every second, making it impossible to browse history. When
  /// this flag is `true`, that auto-reset is skipped; such charts are expected
  /// to reset to live via their own market/round-change handling.
  ///
  /// When `false` (default), existing charts keep the original behavior.
  final bool rollingWindowData;

  /// Creates a copy of this ChartAxisConfig but with the given fields replaced.
  ChartAxisConfig copyWith({
    double? initialTopBoundQuote,
    double? initialBottomBoundQuote,
    double? maxCurrentTickOffset,
    double? initialCurrentTickOffset,
  }) =>
      ChartAxisConfig(
        initialTopBoundQuote: initialTopBoundQuote ?? this.initialTopBoundQuote,
        initialBottomBoundQuote:
            initialBottomBoundQuote ?? this.initialBottomBoundQuote,
        maxCurrentTickOffset: maxCurrentTickOffset ?? this.maxCurrentTickOffset,
        initialCurrentTickOffset:
            initialCurrentTickOffset ?? this.initialCurrentTickOffset,
      );
}
