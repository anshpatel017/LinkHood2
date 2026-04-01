import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Star rating display widget
class RatingStars extends StatelessWidget {
  final double rating;
  final int maxStars;
  final double size;
  final bool showLabel;
  final int? count;

  const RatingStars({
    super.key,
    required this.rating,
    this.maxStars = 5,
    this.size = 16,
    this.showLabel = false,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxStars, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star_rounded, size: size, color: AppColors.starFilled);
          } else if (index < rating.ceil() && rating % 1 > 0) {
            return Icon(Icons.star_half_rounded, size: size, color: AppColors.starFilled);
          }
          return Icon(Icons.star_outline_rounded, size: size, color: AppColors.starEmpty);
        }),
        if (showLabel) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 2),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: size * 0.65,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Interactive star rating input
class RatingInput extends StatelessWidget {
  final int currentRating;
  final ValueChanged<int> onRatingChanged;
  final double size;

  const RatingInput({
    super.key,
    required this.currentRating,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= currentRating
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: starValue <= currentRating
                  ? AppColors.starFilled
                  : AppColors.starEmpty,
            ),
          ),
        );
      }),
    );
  }
}
