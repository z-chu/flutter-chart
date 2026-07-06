import 'package:deriv_chart/src/add_ons/indicators_ui/stochastic_oscillator_indicator/stochastic_oscillator_indicator_config.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_data.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/data_series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/indicators_series/models/stochastic_oscillator_options.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/indicators_series/single_indicator_series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/line_series/line_painter.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/line_series/oscillator_line_painter.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/series.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/chart_series/series_painter.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/animation_info.dart';
import 'package:deriv_chart/src/deriv_chart/chart/data_visualization/models/chart_scale_model.dart';
import 'package:deriv_chart/src/deriv_chart/chart/helpers/indicator.dart';
import 'package:deriv_chart/src/models/chart_config.dart';
import 'package:deriv_chart/src/models/tick.dart';
import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:deriv_technical_analysis/deriv_technical_analysis.dart';
import 'package:flutter/material.dart';

/// A series which shows Stochastic Oscillator Series data calculated
/// from 'entries'.
class StochasticOscillatorSeries extends Series {
  /// Initializes a series which shows shows Stochastic Oscillator data
  /// calculated from [inputIndicator].
  StochasticOscillatorSeries(
    this.inputIndicator,
    this.config, {
    required this.stochasticOscillatorOptions,
    String? id,
  }) : super(id ?? 'StochasticOscillator');

  /// Fast percent StochasticOscillator indicator series.
  late SingleIndicatorSeries fastPercentStochasticIndicatorSeries;

  /// Slow percent StochasticOscillator indicator series.
  late SingleIndicatorSeries slowStochasticIndicatorSeries;

  /// %J line series (J = 3K − 2D). Only built when [config.jLineStyle] is set;
  /// null keeps the original two-line (K/D) behaviour.
  SingleIndicatorSeries? jStochasticIndicatorSeries;

  ///input data
  final Indicator<Tick> inputIndicator;

  /// Configuration of StochasticOscillator.
  final StochasticOscillatorIndicatorConfig config;

  /// Options for StochasticOscillator Indicator.
  final StochasticOscillatorOptions stochasticOscillatorOptions;

  @override
  SeriesPainter<Series>? createPainter() {
    final FastStochasticIndicator<Tick> fastStochasticIndicator =
        FastStochasticIndicator<Tick>.fromIndicator(inputIndicator,
            period: stochasticOscillatorOptions.period);

    final SlowStochasticIndicator<Tick> slowStochasticIndicator =
        SlowStochasticIndicator<Tick>.fromIndicator(fastStochasticIndicator);

    if (config.isSmooth) {
      final SmoothedFastStochasticIndicator<Tick>
          smoothedFastStochasticIndicator =
          SmoothedFastStochasticIndicator<Tick>(fastStochasticIndicator,
              period: stochasticOscillatorOptions.period);

      fastPercentStochasticIndicatorSeries = SingleIndicatorSeries(
        painterCreator: (Series series) => config.showZones
            ? OscillatorLinePainter(
                series as DataSeries<Tick>,
                bottomHorizontalLine: config.overSoldPrice,
                topHorizontalLine: config.overBoughtPrice,
                topHorizontalLinesStyle:
                    config.oscillatorLinesConfig.overboughtStyle,
                bottomHorizontalLinesStyle:
                    config.oscillatorLinesConfig.oversoldStyle,
              )
            : LinePainter(series as DataSeries<Tick>),
        indicatorCreator: () => smoothedFastStochasticIndicator,
        inputIndicator: inputIndicator,
        options: stochasticOscillatorOptions,
        style: config.fastLineStyle,
        lastTickIndicatorStyle: getLastIndicatorStyle(
          config.fastLineStyle.color,
          showLastIndicator: config.showLastIndicator,
        ),
      );

      slowStochasticIndicatorSeries = SingleIndicatorSeries(
        painterCreator: (Series series) =>
            LinePainter(series as DataSeries<Tick>),
        indicatorCreator: () =>
            SmoothedSlowStochasticIndicator<Tick>(slowStochasticIndicator),
        inputIndicator: inputIndicator,
        options: stochasticOscillatorOptions,
        style: config.slowLineStyle,
        lastTickIndicatorStyle: getLastIndicatorStyle(
          config.slowLineStyle.color,
          showLastIndicator: config.showLastIndicator,
        ),
      );
    } else {
      fastPercentStochasticIndicatorSeries = SingleIndicatorSeries(
        painterCreator: (Series series) => config.showZones
            ? OscillatorLinePainter(
                series as DataSeries<Tick>,
                bottomHorizontalLine: config.overSoldPrice,
                topHorizontalLine: config.overBoughtPrice,
                topHorizontalLinesStyle:
                    config.oscillatorLinesConfig.overboughtStyle,
                bottomHorizontalLinesStyle:
                    config.oscillatorLinesConfig.oversoldStyle,
              )
            : LinePainter(series as DataSeries<Tick>),
        indicatorCreator: () => fastStochasticIndicator,
        options: stochasticOscillatorOptions,
        inputIndicator: inputIndicator,
        style: config.fastLineStyle,
        lastTickIndicatorStyle: getLastIndicatorStyle(
          config.fastLineStyle.color,
          showLastIndicator: config.showLastIndicator,
        ),
      );

      slowStochasticIndicatorSeries = SingleIndicatorSeries(
        painterCreator: (Series series) =>
            LinePainter(series as DataSeries<Tick>),
        indicatorCreator: () => slowStochasticIndicator,
        inputIndicator: inputIndicator,
        options: stochasticOscillatorOptions,
        style: config.slowLineStyle,
        lastTickIndicatorStyle: getLastIndicatorStyle(
          config.slowLineStyle.color,
          showLastIndicator: config.showLastIndicator,
        ),
      );
    }

    // %J = 3K − 2D. Opt-in via jLineStyle; builds its own K/D matching the
    // displayed smooth/non-smooth path so it never shares mutable cache with
    // the K/D series above.
    if (config.jLineStyle != null) {
      final int period = stochasticOscillatorOptions.period;
      final CachedIndicator<Tick> kForJ;
      final CachedIndicator<Tick> dForJ;
      if (config.isSmooth) {
        kForJ = SmoothedFastStochasticIndicator<Tick>(
          FastStochasticIndicator<Tick>.fromIndicator(inputIndicator,
              period: period),
          period: period,
        );
        dForJ = SmoothedSlowStochasticIndicator<Tick>(
          SlowStochasticIndicator<Tick>.fromIndicator(
            FastStochasticIndicator<Tick>.fromIndicator(inputIndicator,
                period: period),
          ),
        );
      } else {
        kForJ = FastStochasticIndicator<Tick>.fromIndicator(inputIndicator,
            period: period);
        dForJ = SlowStochasticIndicator<Tick>.fromIndicator(
          FastStochasticIndicator<Tick>.fromIndicator(inputIndicator,
              period: period),
        );
      }
      // Pre-build once and return the same instance (mirrors K/D above).
      final _JStochasticIndicator<Tick> jIndicator =
          _JStochasticIndicator<Tick>(kForJ, dForJ);
      jStochasticIndicatorSeries = SingleIndicatorSeries(
        painterCreator: (Series series) =>
            LinePainter(series as DataSeries<Tick>),
        indicatorCreator: () => jIndicator,
        inputIndicator: inputIndicator,
        options: stochasticOscillatorOptions,
        style: config.jLineStyle,
        lastTickIndicatorStyle: getLastIndicatorStyle(
          config.jLineStyle!.color,
          showLastIndicator: config.showLastIndicator,
        ),
      );
    }
    return null;
  }

  @override
  bool didUpdate(ChartData? oldData) {
    final StochasticOscillatorSeries? series =
        oldData as StochasticOscillatorSeries?;
    final bool _fastUpdated = fastPercentStochasticIndicatorSeries
        .didUpdate(series?.fastPercentStochasticIndicatorSeries);
    final bool _slowUpdated = slowStochasticIndicatorSeries
        .didUpdate(series?.slowStochasticIndicatorSeries);
    final bool _jUpdated = jStochasticIndicatorSeries
            ?.didUpdate(series?.jStochasticIndicatorSeries) ??
        false;

    return _fastUpdated || _slowUpdated || _jUpdated;
  }

  @override
  void onUpdate(int leftEpoch, int rightEpoch) {
    fastPercentStochasticIndicatorSeries.update(leftEpoch, rightEpoch);
    slowStochasticIndicatorSeries.update(leftEpoch, rightEpoch);
    jStochasticIndicatorSeries?.update(leftEpoch, rightEpoch);
  }

  /// K/D (+ J when present) sub-series used for range / epoch aggregation.
  List<ChartData> get _subSeries => <ChartData>[
        fastPercentStochasticIndicatorSeries,
        slowStochasticIndicatorSeries,
        if (jStochasticIndicatorSeries != null) jStochasticIndicatorSeries!,
      ];

  @override
  List<double> recalculateMinMax() => <double>[
        _subSeries.getMinValue(),
        _subSeries.getMaxValue(),
      ];

  @override
  void paint(
    Canvas canvas,
    Size size,
    double Function(int) epochToX,
    double Function(double) quoteToY,
    AnimationInfo animationInfo,
    ChartConfig chartConfig,
    ChartTheme theme,
    ChartScaleModel chartScaleModel,
  ) {
    fastPercentStochasticIndicatorSeries.paint(canvas, size, epochToX, quoteToY,
        animationInfo, chartConfig, theme, chartScaleModel);
    slowStochasticIndicatorSeries.paint(canvas, size, epochToX, quoteToY,
        animationInfo, chartConfig, theme, chartScaleModel);
    jStochasticIndicatorSeries?.paint(canvas, size, epochToX, quoteToY,
        animationInfo, chartConfig, theme, chartScaleModel);
  }

  @override
  int? getMaxEpoch() => _subSeries.getMaxEpoch();

  @override
  int? getMinEpoch() => _subSeries.getMinEpoch();
}

/// %J line indicator: J = 3·%K − 2·%D. Self-contained — holds its own K/D
/// indicators (built by the series to match the smooth/non-smooth path) so it
/// never shares mutable cache with the displayed K/D series.
class _JStochasticIndicator<T extends IndicatorResult>
    extends CachedIndicator<T> {
  /// Initializes from the %K and %D indicators.
  _JStochasticIndicator(this._kIndicator, this._dIndicator)
      : super.fromIndicator(_kIndicator);

  final CachedIndicator<T> _kIndicator;
  final CachedIndicator<T> _dIndicator;

  @override
  T calculate(int index) => createResult(
        index: index,
        quote: 3 * _kIndicator.getValue(index).quote -
            2 * _dIndicator.getValue(index).quote,
      );

  @override
  void copyValuesFrom(covariant _JStochasticIndicator<T> other) {
    super.copyValuesFrom(other);
    _kIndicator.copyValuesFrom(other._kIndicator);
    _dIndicator.copyValuesFrom(other._dIndicator);
  }

  @override
  void invalidate(int index) {
    _kIndicator.invalidate(index);
    _dIndicator.invalidate(index);
    super.invalidate(index);
  }
}
