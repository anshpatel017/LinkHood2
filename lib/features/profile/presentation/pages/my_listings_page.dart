import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../listings/presentation/providers/listing_provider.dart';

class MyListingsPage extends ConsumerWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error loading listings',
          subtitle: err.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.refresh(myListingsProvider),
        ),
        data: (listings) {
          if (listings.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: 'No listings yet',
              subtitle: 'Items you put up for rent will appear here.',
              actionLabel: 'Add Listing',
              onAction: () => context.push('/add-listing'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              top: AppSpacing.sm,
              bottom: 80, // Space for FAB
            ),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = listings[index];
              final catLabel = CategoryConstants.getLabel(item.category);
              final catIcon = CategoryConstants.getIcon(item.category);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () => context.push('/home/item/${item.id}'),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small Image on the left
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: item.hasImages
                              ? Image.network(
                                  item.firstImageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.image_not_supported,
                                      color: AppColors.textSecondary, size: 20),
                                ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        
                        // Content on the right, matching My Requests style
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: category pill + status chip
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    ),
                                    child: Text(
                                      '$catIcon $catLabel',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isAvailable 
                                          ? AppColors.success.withOpacity(0.12)
                                          : AppColors.textTertiary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                    ),
                                    child: Text(
                                      item.isAvailable ? '● Active' : 'Hidden',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: item.isAvailable ? AppColors.success : AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Item name
                              Text(
                                item.title.isEmpty ? 'Unnamed Item' : item.title,
                                style: AppTypography.h4,
                              ),
                              if (item.description != null && item.description!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  item.description!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: AppSpacing.md),

                              // Info row (price and availability)
                              Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.currency_rupee, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.pricePerDay.toStringAsFixed(0)}/day',
                                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  if (item.isInstant)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.flash_on, size: 14, color: AppColors.warning),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Instant',
                                          style: AppTypography.caption.copyWith(color: AppColors.warning),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-listing'),
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
