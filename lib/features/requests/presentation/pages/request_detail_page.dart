import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../features/listings/presentation/providers/listing_provider.dart';
import '../providers/request_provider.dart';

class RequestDetailPage extends ConsumerWidget {
  final String requestId;

  const RequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We try to find the request in the nearby requests since we just clicked it
    final requestsAsync = ref.watch(nearbyRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Error loading request',
          subtitle: err.toString(),
          actionLabel: 'Go Back',
          onAction: () => context.pop(),
        ),
        data: (requests) {
          final requestList = requests.where((r) => r.id == requestId).toList();
          
          if (requestList.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.search_off,
              title: 'Request not found',
              subtitle: 'This request may have been removed or fulfilled.',
              actionLabel: 'Go Back',
              onAction: () => context.pop(),
            );
          }
          
          final request = requestList.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Pill & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        CategoryConstants.getLabel(request.category),
                        style: AppTypography.labelMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Needed',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),

                // Title
                Text(
                  request.itemName,
                  style: AppTypography.h2,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Description
                Text(
                  request.description,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Details Grid
                _DetailsBox(
                  budgetPerDay: request.budgetPerDay,
                  durationDays: request.durationDays,
                  startDate: request.startDate,
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: () => _showOfferItemBottomSheet(context, ref, request),
                    label: 'I Have This Item',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showOfferItemBottomSheet(BuildContext context, WidgetRef ref, dynamic request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _OfferItemSheet(
              requestId: request.id,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _OfferItemSheet extends ConsumerWidget {
  final String requestId;
  final ScrollController scrollController;

  const _OfferItemSheet({
    required this.requestId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: We need the listingProvider imported for this
    final myListingsAsync = ref.watch(myListingsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Select an item to offer', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose from your active listings to fulfill this request. The requester will be notified of your offer.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: myListingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading your items', style: TextStyle(color: AppColors.error))),
              data: (listings) {
                if (listings.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.inventory_2_outlined,
                    title: 'No listings available',
                    subtitle: 'You need to create a listing before you can offer an item.',
                    actionLabel: 'Create Listing',
                    onAction: () {
                      context.pop();
                      context.push('/add-listing');
                    },
                  );
                }

                return ListView.separated(
                  controller: scrollController,
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.all(AppSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      leading: listing.imageUrls.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              child: Image.network(
                                listing.imageUrls.first,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: const Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                            ),
                      title: Text(listing.title, style: AppTypography.h4),
                      subtitle: Text('₹${listing.pricePerDay.toStringAsFixed(0)}/day'),
                      trailing: SizedBox(
                        width: 90,
                        height: 36,
                        child: AppButton(
                          label: 'Offer',
                          onPressed: () async {
                            try {
                            final repo = ref.read(requestRepositoryProvider);
                            await repo.offerListingToRequest(
                              requestId: requestId,
                              listingId: listing.id,
                            );

                            if (context.mounted) {
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Item successfully offered!')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
                              );
                            }
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsBox extends StatelessWidget {
  final double? budgetPerDay;
  final int? durationDays;
  final DateTime? startDate;

  const _DetailsBox({
    this.budgetPerDay,
    this.durationDays,
    this.startDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.currency_rupee,
            label: 'Budget',
            value: budgetPerDay != null ? '₹${budgetPerDay!.toStringAsFixed(0)}/day' : 'Flexible',
            iconColor: AppColors.primary,
          ),
          _buildInfoItem(
            icon: Icons.calendar_today,
            label: 'Duration',
            value: durationDays != null ? '$durationDays Days' : 'Flexible',
            iconColor: AppColors.textSecondary,
          ),
          if (startDate != null)
            _buildInfoItem(
              icon: Icons.event,
              label: 'Needed By',
              value: DateFormat('MMM d').format(startDate!),
              iconColor: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
