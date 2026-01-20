import 'dart:ui';

import 'package:flutter/material.dart';

/// 低层斜线图案配置
class LowLayerPatternConfig {
  /// 创建斜线图案配置
  const LowLayerPatternConfig({
    this.patternColor = const Color(0xFF1F1F1F),
    this.patternSpacing = 4.0,
    this.patternAngle = -45.0,
  });

  /// 斜线图案颜色
  final Color patternColor;

  /// 斜线图案间距（像素）
  final double patternSpacing;

  /// 斜线图案角度（度）
  final double patternAngle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LowLayerPatternConfig &&
          runtimeType == other.runtimeType &&
          patternColor == other.patternColor &&
          patternSpacing == other.patternSpacing &&
          patternAngle == other.patternAngle;

  @override
  int get hashCode =>
      patternColor.hashCode ^ patternSpacing.hashCode ^ patternAngle.hashCode;
}

/// 低层竖线配置
class LowLayerLineConfig {
  /// 创建竖线配置
  const LowLayerLineConfig({
    this.color = const Color(0xFF666666),
    this.isDashed = true,
    this.strokeWidth = 1.0,
    this.dashWidth = 2.0,
    this.dashSpace = 2.0,
  });

  /// 线的颜色
  final Color color;

  /// 是否是虚线
  final bool isDashed;

  /// 线的粗细
  final double strokeWidth;

  /// 虚线模式下，每个虚线段的长度（像素）
  final double dashWidth;

  /// 虚线模式下，虚线之间的间距（像素）
  final double dashSpace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LowLayerLineConfig &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          isDashed == other.isDashed &&
          strokeWidth == other.strokeWidth &&
          dashWidth == other.dashWidth &&
          dashSpace == other.dashSpace;

  @override
  int get hashCode =>
      color.hashCode ^
      isDashed.hashCode ^
      strokeWidth.hashCode ^
      dashWidth.hashCode ^
      dashSpace.hashCode;
}

/// 磨砂背景区域配置
class ChartLowLayerConfig {
  /// 创建磨砂背景配置
  const ChartLowLayerConfig({
    required this.startEpoch,
    required this.endEpoch,
    this.backgroundColor,
    this.patternConfig,
    this.startLineConfig,
    this.endLineConfig,
  });

  /// 开始时间（epoch 时间戳，毫秒）
  final int startEpoch;

  /// 结束时间（epoch 时间戳，毫秒）
  final int endEpoch;

  /// 背景颜色，如果为 null 则使用主题背景色
  final Color? backgroundColor;

  /// 斜线图案配置，如果为 null 则不绘制斜线图案
  final LowLayerPatternConfig? patternConfig;

  /// 开始时间处的竖线配置，如果为 null 则不绘制
  final LowLayerLineConfig? startLineConfig;

  /// 结束时间处的竖线配置，如果为 null 则不绘制
  final LowLayerLineConfig? endLineConfig;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartLowLayerConfig &&
          runtimeType == other.runtimeType &&
          startEpoch == other.startEpoch &&
          endEpoch == other.endEpoch &&
          backgroundColor == other.backgroundColor &&
          patternConfig == other.patternConfig &&
          startLineConfig == other.startLineConfig &&
          endLineConfig == other.endLineConfig;

  @override
  int get hashCode =>
      startEpoch.hashCode ^
      endEpoch.hashCode ^
      backgroundColor.hashCode ^
      patternConfig.hashCode ^
      startLineConfig.hashCode ^
      endLineConfig.hashCode;
}
