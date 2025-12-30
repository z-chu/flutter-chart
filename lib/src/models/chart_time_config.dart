/// Global configuration for chart time display settings.
///
/// This class provides a centralized way to configure how time is displayed
/// throughout the chart components. By default, the chart uses local time.
///
/// Example usage:
/// ```dart
/// // Use UTC time (original behavior)
/// ChartTimeConfig.useLocalTime = false;
///
/// // Use local time (default)
/// ChartTimeConfig.useLocalTime = true;
/// ```
class ChartTimeConfig {
  ChartTimeConfig._();

  /// Whether to display time in local timezone.
  ///
  /// When `true` (default), all time displays will be converted to the device's
  /// local timezone. When `false`, times will be displayed in UTC.
  ///
  /// This affects:
  /// - Crosshair time labels
  /// - X-axis time grid labels
  /// - Drawing tool time labels
  /// - Any other time-related displays in the chart
  static bool useLocalTime = true;

  /// Convenience getter that returns the opposite of [useLocalTime].
  ///
  /// This is useful for APIs that expect an `isUtc` parameter.
  static bool get isUtc => !useLocalTime;
}

