import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/rental.dart';
import '../providers/rental_provider.dart';
import '../../../ratings/presentation/providers/rating_provider.dart';

class RentalCard extends ConsumerWidget {
  final Rental rental;
  final bool isLender;

  const RentalCard({
    super.key,
    required this.rental,
    required this.isLender,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For lenders, show borrower info. For borrowers, show lender info.
    final counterName = rental.counterpartyName ?? 'User';
    final statusColor = _getStatusColor(rental.status);
    final statusText = rental.status.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      elevation: 0,
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    statusText,
                    style: AppTypography.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${rental.startDate.day}/${rental.startDate.month} - ${rental.endDate.day}/${rental.endDate.month}',
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Listing Details
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    image: (rental.listingImages != null && rental.listingImages!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(rental.listingImages!.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (rental.listingImages == null || rental.listingImages!.isEmpty)
                      ? const Icon(Icons.image, color: AppColors.textTertiary)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rental.listingTitle ?? 'Unknown Item', style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isLender ? 'Requested by $counterName' : 'Lent by $counterName',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(CurrencyFormatter.format(rental.totalCost), style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                    Text('${rental.totalDays} days', style: AppTypography.caption),
                  ],
                ),
              ],
            ),

            // Action Buttons (For Lenders to Accept/Reject pending requests)
            if (isLender && rental.isPending) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _updateStatus(ref, 'rejected'),
                    child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: () => _updateStatus(ref, 'accepted'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ],
            
            // Start/Complete Actions for accepted items
            if (rental.isAccepted) ...[
               const SizedBox(height: AppSpacing.md),
               const Divider(color: AppColors.border),
               const SizedBox(height: AppSpacing.sm),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   ElevatedButton(
                     onPressed: () => _updateStatus(ref, isLender ? 'completed' : 'active'), // Simplification: Lender completes, Borrower marks active
                     child: Text(isLender ? 'Mark Completed' : 'Mark Picked Up'),
                   ),
                 ],
               ),
            ],

            // Rated Actions for completed items
            if (rental.isCompleted) ...[
              ref.watch(hasRatedProvider(rental.id)).when(
                data: (hasRated) {
                  if (hasRated) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showRatingDialog(context, ref),
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Rate Experience'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
    int score = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Rate your experience'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < score ? Icons.star : Icons.star_border,
                        color: Colors.amber.shade700,
                        size: 32,
                      ),
                      onPressed: () => setState(() => score = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Leave a comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final rateeId = isLender ? rental.borrowerId : rental.lenderId;
                    await ref.read(ratingControllerProvider).submitRating(
                      rentalId: rental.id,
                      rateeId: rateeId,
                      score: score,
                      comment: commentController.text.trim().isNotEmpty ? commentController.text.trim() : null,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateStatus(WidgetRef ref, String status) {
    ref.read(rentalControllerProvider).updateStatus(rental.id, status);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return AppColors.success;
      case 'active': return Colors.blue;
      case 'completed': return Colors.purple;
      case 'rejected':
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }
}
