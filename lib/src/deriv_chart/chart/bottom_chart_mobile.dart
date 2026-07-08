import 'dart:ui';

import 'package:deriv_chart/src/deriv_chart/chart/mobile_chart_frame_dividers.dart';
import 'package:deriv_chart/src/models/chart_config.dart';
import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:deriv_chart/src/theme/colors.dart';
import 'package:deriv_chart/src/theme/dimens.dart';
import 'package:deriv_chart/src/theme/text_styles.dart';
import 'package:deriv_chart/src/widgets/bottom_indicator_title.dart';
import 'package:deriv_chart/src/widgets/reset_y_axis_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'basic_chart.dart';
import 'bottom_chart.dart';
import 'data_visualization/chart_series/series.dart';
import 'x_axis/x_axis_model.dart';
import 'y_axis/quote_grid.dart';

/// Mobile version of the chart to add the bottom indicators too.
class BottomChartMobile extends BasicChart {
  /// Initializes a bottom chart mobile.
  const BottomChartMobile({
    required Series series,
    required this.granularity,
    required this.title,
    this.showFrame = true,
    int pipSize = 4,
    Key? key,
    this.onHideUnhideToggle,
    this.onSwap,
    this.isHidden = false,
    this.showMoveUpIcon = false,
    this.showMoveDownIcon = false,
    this.bottomChartTitleMargin,
    this.showIndicatorLabels = true,
    this.bottomChartLegend,
    this.edgeYLabels = false,
    super.enableYAxisScaling,
    super.currentTickAnimationDuration,
    super.quoteBoundsAnimationDuration,
  }) : super(key: key, mainSeries: series, pipSize: pipSize);

  /// For candles: Duration of one candle in ms.
  /// For ticks: Average ms difference between two consecutive ticks.
  final int granularity;

  /// Called when an indicator is to be expanded.
  final VoidCallback? onHideUnhideToggle;

  /// Called when an indicator is to moved up/down.
  final SwapCallback? onSwap;

  /// Whether the indicator is hidden or not.
  final bool isHidden;

  /// The title of the bottom chart.
  final String title;

  /// Whether the move up icon should be shown or not.
  final bool showMoveUpIcon;

  /// Whether the move down icon should be shown or not.
  final bool showMoveDownIcon;

  /// Specifies the margin to prevent overlap.
  final EdgeInsets? bottomChartTitleMargin;

  /// Whether to show the frame or not.
  final bool showFrame;

  /// Whether to render the built-in indicator label chip (title + eye/move
  /// icons). Defaults to `true`; set `false` to keep the pane clean.
  final bool showIndicatorLabels;

  /// Optional custom legend rendered at the pane's top-left (in place of the
  /// built-in title chip). `null` (default) keeps the built-in chip, so
  /// existing callers are unaffected (zero regression).
  final Widget? bottomChartLegend;

  /// Whether to pin exactly two y-axis grid labels at the visible min/max
  /// bounds instead of the default interval-based labels (which on a short pane
  /// often collapse to a single mid label). Defaults to `false` (unchanged).
  final bool edgeYLabels;

  @override
  _BottomChartMobileState createState() => _BottomChartMobileState();
}

class _BottomChartMobileState extends BasicChartState<BottomChartMobile> {
  ChartTheme get theme => context.read<ChartTheme>();

  /// Builds a button to reset the Y-axis scaling to auto-fit mode.
  Widget _buildResetYAxisButton() =>
      ResetYAxisButton(onPressed: resetYAxisScale);

  @override
  List<double> calculateGridLineQuotes(YAxisModel yAxisModel) {
    if (!widget.edgeYLabels) {
      return super.calculateGridLineQuotes(yAxisModel);
    }
    // Pin two labels at the visible max/min bounds (top-high, bottom-low),
    // matching gridQuotes() ordering (first = highest, last = lowest).
    final List<double> newGridLineQuotes = <double>[
      yAxisModel.topBoundQuote,
      yAxisModel.bottomBoundQuote,
    ];
    // Preserve the parent's onQuoteAreaChanged diff logic (external callers
    // depend on it; dropping it would silently break them).
    if (newGridLineQuotes.isNotEmpty &&
        (gridLineQuotes == null ||
            gridLineQuotes!.isEmpty ||
            newGridLineQuotes.first != gridLineQuotes!.first ||
            newGridLineQuotes.last != gridLineQuotes!.last)) {
      widget.onQuoteAreaChanged
          ?.call(newGridLineQuotes.first, newGridLineQuotes.last);
    }
    gridLineQuotes = newGridLineQuotes;
    return gridLineQuotes!;
  }

  @override
  Widget build(BuildContext context) {
    final ChartConfig chartConfig = ChartConfig(
      pipSize: widget.pipSize,
      granularity: widget.granularity,
    );

    return Provider<ChartConfig>.value(
      value: chartConfig,
      child: ClipRect(
        child: widget.isHidden
            ? Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _buildCollapsedBottomChart(context),
                  ),
                  _buildDivider(),
                ],
              )
            : Stack(
                children: <Widget>[
                  if (widget.showFrame) _buildChartFrame(context),
                  if (!widget.isHidden)
                    Column(
                      children: <Widget>[
                        Expanded(child: super.build(context)),
                        _buildDivider(),
                      ],
                    ),
                  Positioned(
                    top: 4,
                    left: widget.bottomChartTitleMargin?.left ?? 10,
                    // Custom legend (PM) replaces the built-in title chip;
                    // null falls back to it (highlow / library callers).
                    child: widget.bottomChartLegend ??
                        _buildIndicatorLabelMobile(),
                  ),
                  // Y-axis scale gesture layer - must be on top to intercept gestures
                  // from parent scrollable widgets like CustomScrollView
                  buildYAxisScaleGestureLayer(),
                  // Reset Y-axis scale button - shown when user has manually scaled the Y-axis
                  // Must be above the gesture layer to receive tap events
                  if (widget.enableYAxisScaling)
                    ValueListenableBuilder<bool>(
                      valueListenable: isYAxisScaledNotifier,
                      builder: (context, isScaled, _) => isScaled
                          ? Positioned(
                              bottom: 4,
                              right: 4,
                              child: _buildResetYAxisButton(),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildChartFrame(BuildContext context) => Container(
        constraints: const BoxConstraints.expand(),
        child: MobileChartFrameDividers(
          color: LegacyLightThemeColors.hover,
          rightPadding: (context.read<XAxisModel>().rightPadding ?? 0) +
              context.read<ChartTheme>().gridStyle.labelHorizontalPadding,
          sides: const ChartFrameSides(right: true),
        ),
      );

  Widget _buildIndicatorLabelMobile() => widget.showIndicatorLabels
      ? IndicatorLabelMobile(
          title: widget.title,
          showMoveUpIcon: widget.showMoveUpIcon,
          showMoveDownIcon: widget.showMoveDownIcon,
          isHidden: widget.isHidden,
          onHideUnhideToggle: widget.onHideUnhideToggle,
          onSwap: widget.onSwap,
        )
      : const SizedBox.shrink();

  Widget _buildDivider() => const Divider(
        height: 0.5,
        thickness: 1,
        color: LegacyLightThemeColors.hover,
      );

  Widget _buildCollapsedBottomChart(BuildContext context) => Container(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(
            left: widget.bottomChartTitleMargin?.left ?? 10,
          ),
          child: _buildIndicatorLabelMobile(),
        ),
      );

  @override
  void didUpdateWidget(BottomChartMobile oldChart) {
    super.didUpdateWidget(oldChart);

    xAxis.update(
      minEpoch: widget.mainSeries.getMinEpoch(),
      maxEpoch: widget.mainSeries.getMaxEpoch(),
    );
  }
}

/// Bottom chart options for mobile.
class IndicatorLabelMobile extends StatelessWidget {
  /// Initializes a bottom chart indicator label.
  const IndicatorLabelMobile({
    required this.title,
    required this.showMoveUpIcon,
    required this.showMoveDownIcon,
    required this.isHidden,
    this.onHideUnhideToggle,
    this.onSwap,
    super.key,
  });

  /// The title of the indicator.
  final String title;

  /// Whether to show the move up icon.
  final bool showMoveUpIcon;

  /// Whether to show the move down icon.
  final bool showMoveDownIcon;

  /// Whether the indicator is hidden or not.
  final bool isHidden;

  /// Called when an indicator is to be expanded.
  final VoidCallback? onHideUnhideToggle;

  /// Called when an indicator is to moved up/down.
  final SwapCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final ChartTheme theme = context.read<ChartTheme>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(Dimens.margin04),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: theme.crosshairInformationBoxContainerGlassBackgroundBlur,
            sigmaY: theme.crosshairInformationBoxContainerGlassBackgroundBlur),
        child: Container(
          padding: const EdgeInsets.all(Dimens.margin04),
          decoration: BoxDecoration(
            color: theme.crosshairInformationBoxContainerGlassColor,
            borderRadius: BorderRadius.circular(Dimens.margin04),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Different styling for mobile version.
              BottomIndicatorTitle(
                title,
                theme.textStyle(
                  color: theme.base01Color,
                  textStyle: theme.textStyle(
                    textStyle: TextStyles.caption,
                    color: theme.base01Color,
                  ),
                ),
              ),
              const SizedBox(width: Dimens.margin08),
              _buildIcons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcons(BuildContext context) => Row(
        children: <Widget>[
          _buildIcon(
            iconData: isHidden
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            context: context,
            onPressed: () {
              onHideUnhideToggle?.call();
            },
          ),
          if (showMoveUpIcon)
            _buildIcon(
              iconData: Icons.arrow_upward,
              context: context,
              onPressed: () {
                onSwap?.call(-1);
              },
            ),
          if (showMoveDownIcon)
            _buildIcon(
              iconData: Icons.arrow_downward,
              context: context,
              onPressed: () {
                onSwap?.call(1);
              },
            ),
        ],
      );

  Widget _buildIcon({
    required IconData iconData,
    required BuildContext context,
    void Function()? onPressed,
  }) =>
      Padding(
        padding: const EdgeInsets.only(left: Dimens.margin08),
        child: Material(
          type: MaterialType.circle,
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            icon: Icon(
              iconData,
              size: 16,
              color: context.read<ChartTheme>().base01Color,
            ),
            onPressed: onPressed,
            padding: const EdgeInsets.all(Dimens.margin04),
            constraints: const BoxConstraints(),
          ),
        ),
      );
}
