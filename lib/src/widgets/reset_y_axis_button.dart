import 'package:deriv_chart/src/theme/chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A button widget to reset the Y-axis scaling to auto-fit mode.
class ResetYAxisButton extends StatelessWidget {
  /// Creates a reset Y-axis button.
  const ResetYAxisButton({
    required this.onPressed,
    super.key,
  });

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ChartTheme theme = context.read<ChartTheme>();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton(
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          fixedSize: const Size(20, 20),
          foregroundColor: theme.crosshairInformationBoxTextDefault,
          backgroundColor:
              theme.crosshairInformationBoxContainerNormalColor.withValues(
            alpha: 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        icon: const Text('A', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}
