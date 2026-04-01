import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Primary action button
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textOnPrimary,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconMd),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(label, style: AppTypography.button),
        ],
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
