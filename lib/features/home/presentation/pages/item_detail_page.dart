import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../listings/presentation/providers/listing_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../reports/presentation/providers/report_provider.dart';

class ItemDetailPage extends ConsumerWidget {
  final String listingId;
  const ItemDetailPage({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppColors.error),
            onPressed: () => _showReportDialog(context, ref),
          ),
        ],
      ),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (listing) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image slider or placeholder
              Container(
                height: 280,
                width: double.infinity,
                color: AppColors.surfaceVariant,
                child: listing.hasImages
                    ? PageView.builder(
                        itemCount: listing.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            listing.imageUrls[index],
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 64, color: AppColors.textTertiary),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: AppTypography.h3),
                    const SizedBox(height: AppSpacing.sm),
                    Text('${CurrencyFormatter.format(listing.pricePerDay)}/day',
                        style: AppTypography.price.copyWith(color: AppColors.primary)),
                    const SizedBox(height: AppSpacing.lg),
                    
                    // Owner card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: listing.ownerAvatar != null
                                ? NetworkImage(listing.ownerAvatar!)
                                : null,
                            child: listing.ownerAvatar == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(listing.ownerName ?? 'Neighbor', style: AppTypography.labelLarge),
                                if (listing.ownerRating != null)
                                  RatingStars(rating: listing.ownerRating!, size: 14, showLabel: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    Text('Description', style: AppTypography.h4),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      listing.description ?? 'No description provided.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    
                    if (listing.depositAmount > 0) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Text('Security Deposit', style: AppTypography.h4),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Refundable deposit of ${CurrencyFormatter.format(listing.depositAmount)} required.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: listingAsync.hasValue ? Container(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: AppButton(
            label: listingAsync.value!.isInstant ? 'Instant Rent' : 'Request to Rent',
            onPressed: () {
              context.go('/home/item/$listingId/request');
            },
          ),
        ),
      ) : null,
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Why are you reporting this listing?'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g., Inappropriate content, scam...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              try {
                await ref.read(reportControllerProvider).submitReport(
                  itemType: 'listing',
                  reason: 'User Report',
                  reportedItemId: listingId,
                  description: reasonController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Report submitted successfully.')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}
