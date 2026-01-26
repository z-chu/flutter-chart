import 'dart:async';
import 'dart:ui';

import 'package:deriv_chart/src/deriv_chart/chart/gestures/double_tap_up_details.dart';
import 'package:flutter/material.dart';

/// Duration for which you have to hold one finger without moving until
/// long press is triggered.
/// (small deviation is allowed, see [longPressHoldRadius])
const Duration longPressHoldDuration = Duration(milliseconds: 500);

/// If contact point is moved by more than [longPressHoldRadius] from
/// its original place and [longPressHoldDuration] hasn't elapsed yet,
/// long press is cancelled.
const int longPressHoldRadius = 5;

/// If contact point is moved by more than [tapRadius] from its original place,
/// tap is cancelled.
const double tapRadius = 5;

/// Maximum time between two taps to be considered a double tap.
const Duration doubleTapTimeout = Duration(milliseconds: 300);

/// Maximum distance between two taps to be considered a double tap.
const double doubleTapSlop = 18.0;

/// Callback signature for double tap events.
/// 
/// Note: This is a wrapper class instead of a simple typedef to distinguish
/// it from [GestureTapUpCallback] when using runtime type checking with
/// `whereType<T>()` in [GestureManagerState].
typedef GestureDoubleTapCallback = void Function(DoubleTapUpDetails details);

/// Widget to track pan and scale gestures on one area.
///
/// GestureDetector doesn't allow to track both Pan and Scale gestures
/// at the same time.
///
/// a. Scale is treated as a super set of Pan.
/// b. Scale is triggered even when there is only one finger in contact with the
/// screen.
///
/// Because of (a) and (b) it is possible to keep track of both Pan and Scale by
/// treating ScaleUpdate with 1 finger as PanUpdate.
///
/// Custom long press detection, because adding `onLongPress` callback to
/// GestureDetector will result in a scale/pan delay. It happens because having
/// two gesture callbacks (e.g. "longpress" and "scale") will result in a
/// few moments of delay while GestureDetector is figuring out which gesture is
/// being performed. This delay is quite noticable.
///
/// This widget adds longpress detection without adding delay to scale/pan.
class CustomGestureDetector extends StatefulWidget {
  /// Creates a widget to track pan and scale gestures on one area.
  const CustomGestureDetector({
    required this.child,
    Key? key,
    this.onScaleAndPanStart,
    this.onScaleUpdate,
    this.onPanUpdate,
    this.onScaleAndPanEnd,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onTapUp,
    this.onDoubleTap,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// The pointers in contact with the screen have established a focal point and
  /// initial scale of 1.0.
  final GestureScaleStartCallback? onScaleAndPanStart;

  /// The pointers in contact with the screen have indicated a new focal point and/or scale.
  final GestureScaleUpdateCallback? onScaleUpdate;

  /// Called when a pointer that triggered an `onPointerDown` is no longer in
  /// contact with the screen.
  final GestureDragUpdateCallback? onPanUpdate;

  /// The pointers are no longer in contact with the screen.
  final GestureScaleEndCallback? onScaleAndPanEnd;

  /// Called when a long press gesture with a primary button has been
  /// recognized.
  ///
  /// Triggered when a pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  final GestureLongPressStartCallback? onLongPressStart;

  /// A pointer has been drag-moved after a long press with a primary button.
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  /// Called when a long press gesture with a primary button has been
  /// recognized.
  ///
  /// Triggered when a pointer has remained in contact with the screen at the
  /// same location for a long period of time.
  final GestureLongPressEndCallback? onLongPressEnd;

  /// A pointer that will trigger a tap with a primary button has stopped
  /// contacting the screen at a particular location.
  /// This triggers immediately before `onTap` in the case of the tap gesture
  /// winning. If the tap gesture did not win, `onTapCancel` is called instead.
  final GestureTapUpCallback? onTapUp;

  /// Called when a double tap gesture has been recognized.
  final GestureDoubleTapCallback? onDoubleTap;

  @override
  _CustomGestureDetectorState createState() => _CustomGestureDetectorState();
}

class _CustomGestureDetectorState extends State<CustomGestureDetector> {
  int get pointersDown => _pointersDown;
  int _pointersDown = 0;

  set pointersDown(int value) {
    _onPointersDownWillChange(value);
    _pointersDown = value;
  }

  Offset _localStartPoint = Offset.zero;
  Offset _localLastPoint = Offset.zero;
  Offset _globalStartPoint = Offset.zero;
  Offset _globalLastPoint = Offset.zero;
  PointerDeviceKind? _lastPointerKind;

  bool _tap = false;
  bool _longPressed = false;
  Timer? _longPressTimer;

  // Double tap detection
  DateTime? _lastTapTime;
  Offset? _lastTapLocalPosition;
  Timer? _singleTapTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _singleTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (PointerDownEvent event) {
          _lastPointerKind = event.kind;
          _localStartPoint = event.localPosition;
          _localLastPoint = event.localPosition;
          _globalStartPoint = event.position;
          _globalLastPoint = event.position;
          pointersDown += 1;
        },
        onPointerCancel: (PointerCancelEvent event) {
          _resetDoubleTapState();
          pointersDown -= 1;
        },
        onPointerUp: (PointerUpEvent event) {
          // Update the last point with the current position when pointer is lifted
          _localLastPoint = event.localPosition;
          _globalLastPoint = event.position;
          _lastPointerKind = event.kind;
          pointersDown -= 1;
        },
        child: GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: widget.onScaleAndPanEnd,
          child: widget.child,
        ),
      );

  void _onPointersDownWillChange(int futureValue) {
    // 在第一个指针按下时
    if (_pointersDown == 0 && futureValue == 1) {
      // 取消正在等待的单击 Timer，防止它在 _handleTap 之前清除 _lastTapTime
      // 这样当第二次点击发生时，_lastTapTime 仍然有效，可以正确检测双击
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
      
      // 检查并清除过期的双击状态
      if (_lastTapTime != null && 
          DateTime.now().difference(_lastTapTime!) >= doubleTapTimeout) {
        _resetDoubleTapState();
      }
      
      _tap = true;
      _longPressTimer = Timer(
        longPressHoldDuration,
        _onLongPressStart,
      );
    }

    // 添加第二个指针时取消双击检测
    if (_pointersDown == 1 && futureValue == 2) {
      _tap = false;
      _longPressTimer?.cancel();
      if (_longPressed) {
        _onLongPressEnd();
      }
      // 多指操作时清除双击状态
      _resetDoubleTapState();
    }

    // 移除了最后一个指针
    if (_pointersDown == 1 && futureValue == 0) {
      _longPressTimer?.cancel();
      if (_longPressed) {
        _onLongPressEnd();
      } else if (_tap) {
        final double distance = (_localStartPoint - _localLastPoint).distance;

        // Only trigger tap if the distance is within the threshold
        if (distance <= tapRadius) {
          _handleTap();
        }
      }
    }
  }

  void _handleTap() {
    final TapUpDetails tapDetails = TapUpDetails(
      globalPosition: _globalLastPoint,
      localPosition: _localLastPoint,
      kind: _lastPointerKind ?? PointerDeviceKind.touch,
    );

    final DateTime now = DateTime.now();
    
    // DEBUG
    debugPrint('========== _handleTap ==========');
    debugPrint('_lastTapTime: $_lastTapTime');
    debugPrint('_lastTapLocalPosition: $_lastTapLocalPosition');
    debugPrint('_localLastPoint: $_localLastPoint');
    if (_lastTapTime != null) {
      debugPrint('timeDiff: ${now.difference(_lastTapTime!).inMilliseconds}ms (threshold: ${doubleTapTimeout.inMilliseconds}ms)');
    }
    if (_lastTapLocalPosition != null) {
      debugPrint('distance: ${(_localLastPoint - _lastTapLocalPosition!).distance} (threshold: $doubleTapSlop)');
    }

    // Check if this is a double tap
    // 必须满足：1) 有上次点击记录 2) 时间间隔小于阈值 3) 距离小于阈值
    final bool isDoubleTap = _lastTapTime != null &&
        _lastTapLocalPosition != null &&
        now.difference(_lastTapTime!) < doubleTapTimeout &&
        (_localLastPoint - _lastTapLocalPosition!).distance < doubleTapSlop;

    debugPrint('isDoubleTap: $isDoubleTap');

    if (isDoubleTap) {
      debugPrint('>>> DOUBLE TAP <<<');
      // This is a double tap
      // 先取消单点计时器，防止触发 onTapUp
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
      
      // 先清除状态，再触发回调，确保回调中的任何操作不会受到残留状态影响
      _resetDoubleTapState();
      widget.onDoubleTap?.call(DoubleTapUpDetails(tapUpDetails: tapDetails));
    } else {
      debugPrint('>>> SINGLE TAP (start timer) <<<');
      // This might be the first tap of a double tap, or a single tap
      // 先清除之前可能残留的状态（包括过期的 Timer）
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
      
      // 记录本次点击
      _lastTapTime = now;
      _lastTapLocalPosition = _localLastPoint;

      // If double tap callback is registered, delay single tap to wait for potential second tap
      if (widget.onDoubleTap != null) {
        debugPrint('widget.onDoubleTap != null, delaying onTapUp');
        // 使用闭包捕获当前的 tapDetails，因为后续点击可能会改变位置
        final TapUpDetails capturedTapDetails = tapDetails;
        
        _singleTapTimer = Timer(doubleTapTimeout, () {
          debugPrint('>>> Timer fired, _singleTapTimer: $_singleTapTimer <<<');
          // Timer 触发时，检查是否仍然有效
          // 如果 _singleTapTimer 已经被设为 null，说明被取消了（双击或其他操作）
          if (_singleTapTimer != null) {
            debugPrint('>>> SINGLE TAP CONFIRMED <<<');
            // 先清除状态
            _resetDoubleTapState();
            // 再触发单点回调
            widget.onTapUp?.call(capturedTapDetails);
          }
        });
      } else {
        debugPrint('widget.onDoubleTap == null, immediate onTapUp');
        // No double tap callback, trigger single tap immediately
        // 没有双击回调时，也要清除状态
        _resetDoubleTapState();
        widget.onTapUp?.call(tapDetails);
      }
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    // 注意：不要覆盖 _localStartPoint！
    // _localStartPoint 在 onPointerDown 中已经被设置为正确的起始位置
    // 如果在这里覆盖，会导致 tap 距离计算错误
    // 
    // 只更新 _localLastPoint 用于后续的 pan/scale 计算
    _localLastPoint = details.localFocalPoint;

    // 注意：这里不应该取消 _singleTapTimer 或清除 _lastTapTime
    // 因为 onScaleStart 会在每次点击时被调用（即使是简单的 tap）
    // 如果在这里取消 Timer，会导致单击的 onTapUp 永远不会被触发
    // 如果在这里清除 _lastTapTime，会导致双击检测失败
    //
    // 双击检测的正确流程是：
    // 1. 第一次点击 → _handleTap 设置 _lastTapTime，启动 Timer
    // 2. 第二次点击 → _handleTap 检测到双击，取消 Timer，触发 onDoubleTap
    // 3. 如果没有第二次点击 → Timer 触发，触发 onTapUp
    
    widget.onScaleAndPanStart?.call(details);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_pointersDown == 1) {
      _onSinglePointerMoveUpdate(details);
    } else {
      widget.onScaleUpdate?.call(details);
    }
  }

  void _onSinglePointerMoveUpdate(ScaleUpdateDetails details) {
    if (_longPressed) {
      _onLongPressMoveUpdate(details);
    } else {
      final double distanceFromStart =
          (_localStartPoint - details.localFocalPoint).distance;

      if (distanceFromStart > longPressHoldRadius) {
        _tap = false;
        _longPressTimer?.cancel();
        // 移动超过阈值时清除双击状态
        _resetDoubleTapState();
      }
      _onPanUpdate(details);
    }
  }

  void _onPanUpdate(ScaleUpdateDetails details) {
    widget.onPanUpdate?.call(DragUpdateDetails(
      delta: details.localFocalPoint - _localLastPoint,
      globalPosition: details.focalPoint,
      localPosition: details.localFocalPoint,
    ));
    _localLastPoint = details.localFocalPoint;
  }

  void _onLongPressStart() {
    // 长按开始时清除双击状态
    _resetDoubleTapState();
    
    _longPressed = true;
    widget.onLongPressStart?.call(LongPressStartDetails(
      globalPosition: _globalStartPoint,
      localPosition: _localStartPoint,
    ));
  }

  void _onLongPressMoveUpdate(ScaleUpdateDetails details) {
    widget.onLongPressMoveUpdate?.call(LongPressMoveUpdateDetails(
      localPosition: details.localFocalPoint,
    ));
  }

  void _onLongPressEnd() {
    // 长按结束时清除双击状态
    _resetDoubleTapState();
    
    _longPressed = false;
    widget.onLongPressEnd?.call(const LongPressEndDetails());
  }

  /// 重置双击相关的所有状态
  void _resetDoubleTapState() {
    _lastTapTime = null;
    _lastTapLocalPosition = null;
    if (_singleTapTimer != null) {
      _singleTapTimer?.cancel();
      _singleTapTimer = null;
    }
  }
}