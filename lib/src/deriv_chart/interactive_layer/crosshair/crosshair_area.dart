import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/data_series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/chart_date_utils.dart';
import 'package:deriv_chart/src/deriv_chart/chart/x_axis/x_axis_model.dart';
import 'package:deriv_chart/src/models/chart_time_config.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/crosshair/crosshair_highlight_painter.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/crosshair/crosshair_variant.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/crosshair/large_screen_crosshair_line_painter.dart';
import 'package:deriv_chart/src/deriv_chart/interactive_layer/crosshair/small_screen_crosshair_line_painter.dart';
import 'package:deriv_chart/src/models/tick.dart';
import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'crosshair_details.dart';

/// A widget that displays crosshair details on a chart.
///
/// This widget shows information about a specific point on the chart when the user
/// interacts with it through long press or hover. It displays crosshair lines,
/// price and time labels, and detailed information about the data point.
class CrosshairArea extends StatelessWidget {
  /// Initializes a widget to display candle/point details on longpress in a chart.
  const CrosshairArea({
    required this.mainSeries,
    required this.quoteToCanvasY,
    required this.quoteFromCanvasY,
    required this.crosshairTick,
    required this.cursorPosition,
    required this.animationDuration,
    required this.crosshairVariant,
    required this.isTickWithinDataRange,
    required this.updateAndFindClosestTick,
    this.pipSize = 4,
    Key? key,
  }) : super(key: key);

  /// The main series of the chart.
  final DataSeries<Tick> mainSeries;

  /// Number of decimal digits when showing prices.
  final int pipSize;

  /// Conversion function for converting quote to chart's canvas' Y position.
  final double Function(double) quoteToCanvasY;

  /// Conversion function for converting chart's canvas' Y position to quote.
  final double Function(double) quoteFromCanvasY;

  /// The tick to display in the crosshair.
  final Tick? crosshairTick;

  /// The position of the cursor.
  final Offset cursorPosition;

  /// The duration for animations.
  final Duration animationDuration;

  /// The variant of the crosshair to be used.
  /// This is used to determine the type of crosshair to display.
  /// The default is [CrosshairVariant.smallScreen].
  /// [CrosshairVariant.largeScreen] is mostly for web.
  final CrosshairVariant crosshairVariant;

  /// Whether the current tick is within the actual data range.
  /// When false, the tick is a virtual tick created for cursor positions outside data range.
  /// This is used to determine whether to show the crosshair highlight.
  /// If true, the crosshair will highlight the tick; if false, it will not.
  /// This is useful for distinguishing between actual data points and virtual ticks.
  final bool isTickWithinDataRange;

  /// Function to update and find the closest tick based on cursor position.
  ///
  /// Takes an optional [double] parameter representing the cursor X position.
  /// If no position is provided, it uses the last known long press position.
  /// Returns the closest [Tick] to the specified or default position, or null if none found.
  final Tick? Function([double?]) updateAndFindClosestTick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      Tick? updatedCrosshairTick = crosshairTick;

      if (cursorPosition.dx != 0) {
        updatedCrosshairTick = updateAndFindClosestTick(cursorPosition.dx);
      }
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child:
            buildCrosshairContent(context, constraints, updatedCrosshairTick),
      );
    });
  }

  /// Builds the content of the crosshair, including lines, dots, and information boxes.
  ///
  /// This method constructs the visual elements of the crosshair based on the current
  /// tick and cursor position.
  ///
  /// [context] The build context.
  /// [constraints] The layout constraints for the crosshair area.
  Widget buildCrosshairContent(
      BuildContext context, BoxConstraints constraints, Tick? tick) {
    if (tick == null) {
      return const SizedBox.shrink();
    }

    final XAxisModel xAxis = context.watch<XAxisModel>();
    final ChartTheme theme = context.read<ChartTheme>();
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        AnimatedPositioned(
          duration: animationDuration,
          left: xAxis.xFromEpoch(tick.epoch),
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: crosshairVariant == CrosshairVariant.smallScreen
                ? SmallScreenCrosshairLinePainter(
                    theme: theme,
                  )
                : LargeScreenCrosshairLinePainter(
                    theme: theme,
                    cursorY: cursorPosition.dy,
                  ),
          ),
        ),
        AnimatedPositioned(
          top: quoteToCanvasY(tick.quote),
          left: xAxis.xFromEpoch(tick.epoch),
          duration: animationDuration,
          child: CustomPaint(
            size: Size(1, constraints.maxHeight),
            painter: crosshairVariant == CrosshairVariant.smallScreen
                ? mainSeries.getCrosshairDotPainter(theme)
                : null,
          ),
        ),
        if (isTickWithinDataRange)
          _buildCrosshairTickHightlight(
              constraints: constraints, xAxis: xAxis, theme: theme, tick: tick),
        // Add crosshair quote label at the right side of the chart
        if (crosshairVariant != CrosshairVariant.smallScreen &&
            cursorPosition.dy > 0)
          Positioned(
            top: cursorPosition.dy,
            right: 0,
            child: FractionalTranslation(
              translation: const Offset(0, -0.5), // Center the label vertically
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.crosshairInformationBoxContainerNormalColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  quoteFromCanvasY(cursorPosition.dy).toStringAsFixed(pipSize),
                  style: theme.crosshairAxisLabelStyle.copyWith(
                    color: theme.crosshairInformationBoxTextDefault,
                  ),
                ),
              ),
            ),
          ),
        // Add vertical date label at the bottom of the chart
        if (crosshairVariant != CrosshairVariant.smallScreen)
          Positioned(
            bottom: 0,
            left: xAxis.xFromEpoch(tick.epoch),
            child: FractionalTranslation(
              translation:
                  const Offset(-0.5, 0.85), // Center the label horizontally
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.crosshairInformationBoxContainerNormalColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ChartDateUtils.formatDateTimeWithSeconds(
                    tick.epoch,
                    isUtc: ChartTimeConfig.isUtc,
                  ),
                  style: theme.crosshairAxisLabelStyle.copyWith(
                    color: theme.crosshairInformationBoxTextDefault,
                  ),
                ),
              ),
            ),
          ),
        if (isTickWithinDataRange)
          _buildCrosshairDetails(constraints, xAxis, tick),
      ],
    );
  }

  AnimatedPositioned _buildCrosshairDetails(
      BoxConstraints constraints, XAxisModel xAxis, Tick? tick) {
    // For smallScreen: center the info box on the selected tick (original behavior)
    // For largeScreen: position info box on the opposite side of the tick to avoid covering it
    final bool isSmallScreen = crosshairVariant == CrosshairVariant.smallScreen;

    if (isSmallScreen) {
      // SmallScreen mode: center the info box on the selected tick
      return AnimatedPositioned(
        duration: animationDuration,
        top: 8,
        bottom: 0,
        width: constraints.maxWidth,
        left: xAxis.xFromEpoch(tick!.epoch) - constraints.maxWidth / 2,
        child: Align(
          alignment: Alignment.topCenter,
          child: CrosshairDetails(
            mainSeries: mainSeries,
            crosshairTick: tick,
            pipSize: pipSize,
            crosshairVariant: crosshairVariant,
          ),
        ),
      );
    }

    // LargeScreen mode: position info box on the opposite side of the tick
    // Determine if the tick is on the right side of the chart area
    // Use graphAreaWidth (chart drawing area) instead of full width to exclude quote labels area
    final double tickX = xAxis.xFromEpoch(tick!.epoch);
    final double chartAreaWidth = xAxis.graphAreaWidth ?? constraints.maxWidth;
    final bool isTickOnRightSide = tickX > chartAreaWidth / 2;

    // Calculate the right padding (quote labels area width)
    final double rightPadding = xAxis.rightPadding ?? 0;

    return AnimatedPositioned(
      duration: animationDuration,
      // Position the details above the cursor with a gap
      top: 8,
      bottom: 0,
      // If tick is on right side, show info box on left; otherwise show on right
      // This prevents the info box from covering the selected candlestick
      // When showing on right, add rightPadding to keep it within the chart area
      left: isTickOnRightSide ? 16 : null,
      right: isTickOnRightSide ? null : 16 + rightPadding,
      child: Align(
        alignment: isTickOnRightSide ? Alignment.topLeft : Alignment.topRight,
        child: CrosshairDetails(
          mainSeries: mainSeries,
          crosshairTick: tick,
          pipSize: pipSize,
          crosshairVariant: crosshairVariant,
        ),
      ),
    );
  }

  /// Builds a widget that highlights the current tick at the crosshair position.
  ///
  /// This method creates a visual highlight for the data point (tick, candle, etc.)
  /// that the crosshair is currently pointing to. It delegates the actual painting
  /// to a series-specific highlight painter obtained from the main series.
  ///
  /// The highlight is positioned at the exact location of the data point and provides
  /// visual feedback to the user about which specific data element they are examining.
  /// Different chart types (line, candle, OHLC) will have different highlight visualizations.
  ///
  /// Parameters:
  /// * [constraints] - The layout constraints for the crosshair area.
  /// * [xAxis] - The X-axis model providing epoch-to-coordinate conversion and granularity.
  /// * [theme] - The chart theme containing colors and styles for the highlight.
  ///
  /// Returns:
  /// A positioned widget containing the custom painter for the highlight, or an empty
  /// widget if no highlight painter is available for the current series type.
  Widget _buildCrosshairTickHightlight(
      {required BoxConstraints constraints,
      required XAxisModel xAxis,
      required ChartTheme theme,
      required Tick? tick}) {
    if (tick == null) {
      return const SizedBox.shrink();
    }

    // Get the appropriate highlight painter for the current tick based on the series type
    final CrosshairHighlightPainter? highlightPainter =
        mainSeries.getCrosshairHighlightPainter(
      tick,
      quoteToCanvasY,
      xAxis.xFromEpoch(tick.epoch),
      xAxis.granularity,
      xAxis.xFromEpoch,
      theme,
    );

    if (highlightPainter == null) {
      return const SizedBox.shrink();
    }

    return AnimatedPositioned(
      duration: animationDuration,
      left: 0,
      top: 0,
      child: CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: highlightPainter,
      ),
    );
  }
}
