import 'package:flutter/material.dart';
import '../../features/listings/domain/entities/listing.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/currency_formatter.dart';
import '../utils/distance_formatter.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image header
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  listing.hasImages
                      ? Image.network(
                          listing.firstImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  
                  // Distance badge
                  if (listing.distanceMeters != null)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              DistanceFormatter.format(listing.distanceMeters!),
                              style: AppTypography.caption.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  // Instant indicator
                  if (listing.isInstant)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            // Content body
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            listing.title,
                            style: AppTypography.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${CurrencyFormatter.format(listing.pricePerDay)}/d',
                          style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xs),
                    
                    // Owner details row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: listing.ownerAvatar != null
                              ? NetworkImage(listing.ownerAvatar!)
                              : null,
                          child: listing.ownerAvatar == null
                              ? const Icon(Icons.person, size: 12, color: AppColors.textTertiary)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            listing.ownerName ?? 'Neighbor',
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (listing.ownerRating != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.star, size: 12, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text(
                            listing.ownerRating!.toStringAsFixed(1),
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 32),
      ),
    );
  }
}
