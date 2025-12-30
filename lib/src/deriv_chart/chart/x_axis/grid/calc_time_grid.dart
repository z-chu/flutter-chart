import 'package:deriv_chart/src/models/chart_time_config.dart';

const Duration _week = Duration(days: DateTime.daysPerWeek);
const Duration _day = Duration(days: 1);
const Duration _month = Duration(days: 30);

/// Creates a list of [DateTime] with gaps of [timeGridInterval].
///
/// The returned timestamps respect the global [ChartTimeConfig.useLocalTime] setting.
List<DateTime> gridTimestamps({
  required Duration timeGridInterval,
  required int leftBoundEpoch,
  required int rightBoundEpoch,
}) {
  final bool isUtc = ChartTimeConfig.isUtc;
  final List<DateTime> timestamps = <DateTime>[];
  final DateTime rightBoundTime =
      DateTime.fromMillisecondsSinceEpoch(rightBoundEpoch, isUtc: isUtc);

  DateTime t = _gridEpochStart(timeGridInterval, leftBoundEpoch, isUtc: isUtc);

  while (t.compareTo(rightBoundTime) <= 0) {
    timestamps.add(t);
    t = timeGridInterval == _month
        ? _addMonth(t, isUtc: isUtc)
        : t.add(timeGridInterval);
  }
  return timestamps;
}

DateTime _gridEpochStart(Duration timeGridInterval, int leftBoundEpoch,
    {required bool isUtc}) {
  if (timeGridInterval == _month) {
    return _closestFutureMonthStart(leftBoundEpoch, isUtc: isUtc);
  } else if (timeGridInterval == _week) {
    final DateTime t = _closestFutureDayStart(leftBoundEpoch, isUtc: isUtc);
    final int daysUntilMonday = (8 - t.weekday) % 7;
    return t.add(Duration(days: daysUntilMonday));
  } else if (timeGridInterval == _day) {
    return _closestFutureDayStart(leftBoundEpoch, isUtc: isUtc);
  } else {
    final int diff = timeGridInterval.inMilliseconds;
    final int firstLeft = (leftBoundEpoch / diff).ceil() * diff;
    return DateTime.fromMillisecondsSinceEpoch(firstLeft, isUtc: isUtc);
  }
}

DateTime _closestFutureDayStart(int epoch, {required bool isUtc}) {
  final DateTime time =
      DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: isUtc);
  final DateTime dayStart = isUtc
      ? DateTime.utc(time.year, time.month, time.day)
      : DateTime(time.year, time.month, time.day); // time 00:00:00
  return dayStart.isBefore(time) ? dayStart.add(_day) : dayStart;
}

DateTime _closestFutureMonthStart(int epoch, {required bool isUtc}) {
  final DateTime time =
      DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: isUtc);
  final DateTime monthStart = isUtc
      ? DateTime.utc(time.year, time.month)
      : DateTime(time.year, time.month); // day 1, time 00:00:00
  return monthStart.isBefore(time)
      ? _addMonth(monthStart, isUtc: isUtc)
      : monthStart;
}

DateTime _addMonth(DateTime time, {required bool isUtc}) => isUtc
    ? DateTime.utc(time.year, time.month + 1)
    : DateTime(time.year, time.month + 1);

/// Px width of duration in ms on time axis with current scale.
/// Conversion callback dependency of [timeGridInterval].
typedef PxFromMs = double Function(int ms);

/// Returns the first time interval which has the enough distance between lines.
Duration timeGridInterval(
  PxFromMs pxFromMs, {
  double minDistanceBetweenLines = 100,
  List<Duration> intervals = const <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 8),
    _day,
    Duration(days: 4),
    _week,
    Duration(days: 14),
    Duration(days: 21),
    _month,
  ],
}) {
  bool hasEnoughDistanceBetweenLines(Duration interval) {
    final double distanceBetweenLines = pxFromMs(interval.inMilliseconds);
    return distanceBetweenLines >= minDistanceBetweenLines;
  }

  return intervals.firstWhere(
    hasEnoughDistanceBetweenLines,
    orElse: () => intervals.last,
  );
}
