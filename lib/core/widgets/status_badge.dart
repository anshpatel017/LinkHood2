import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../core/constants/api_constants.dart';

/// Status badge for rental status display
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        config.label,
        style: AppTypography.labelSmall.copyWith(
          color: config.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case ApiConstants.statusPending:
        return _StatusConfig('Pending', AppColors.statusPending);
      case ApiConstants.statusAccepted:
        return _StatusConfig('Accepted', AppColors.statusAccepted);
      case ApiConstants.statusActive:
        return _StatusConfig('Active', AppColors.statusActive);
      case ApiConstants.statusCompleted:
        return _StatusConfig('Completed', AppColors.statusCompleted);
      case ApiConstants.statusCancelled:
        return _StatusConfig('Cancelled', AppColors.statusCancelled);
      case ApiConstants.statusDisputed:
        return _StatusConfig('Disputed', AppColors.statusDisputed);
      case ApiConstants.requestOpen:
        return _StatusConfig('Open', AppColors.statusActive);
      case ApiConstants.requestFulfilled:
        return _StatusConfig('Fulfilled', AppColors.statusCompleted);
      case ApiConstants.requestExpired:
        return _StatusConfig('Expired', AppColors.statusCancelled);
      default:
        return _StatusConfig(status, AppColors.textSecondary);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}
