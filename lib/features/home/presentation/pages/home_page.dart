import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../listings/presentation/providers/listing_provider.dart';
import '../../../requests/presentation/providers/request_provider.dart';
import '../../../../core/constants/category_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/listing_card.dart';
import '../../../../services/notification_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read providers
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final listingsAsync = ref.watch(nearbyListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RentNear'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Listing',
            onPressed: () => context.go('/add-listing'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items near you...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Category Filter Tabs
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              children: [
                _buildCategoryChip('all', 'All', selectedCategory == null),
                ...CategoryConstants.allCategories.map((cat) =>
                  _buildCategoryChip(cat, CategoryConstants.getLabel(cat), selectedCategory == cat),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Listings Grid
          Expanded(
            child: listingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => EmptyStateWidget(
                icon: Icons.error_outline,
                title: 'Something went wrong',
                subtitle: err.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.refresh(nearbyListingsProvider),
              ),
              data: (listings) {
                // Apply local text search filter if any
                var filtered = listings;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((l) => l.title.toLowerCase().contains(_searchQuery)).toList();
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Nearby Items
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.md),
                        child: Text('Nearby Items', style: AppTypography.h3),
                      ),
                      SizedBox(
                        height: 280, // Approximate height of ListingCard
                        child: filtered.isEmpty
                            ? const Center(child: Text('No items nearby matching criteria.', style: TextStyle(color: AppColors.textSecondary)))
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                                scrollDirection: Axis.horizontal,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return SizedBox(
                                    width: 180, // Fixed width for horizontal scrolling
                                    child: ListingCard(
                                      listing: item,
                                      onTap: () => context.go('/home/item/${item.id}'),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Section 2: Nearby Requests
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.sm),
                        child: Text('Nearby Requests', style: AppTypography.h3),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final requestsAsync = ref.watch(nearbyRequestsProvider);
                          return requestsAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Padding(
                              padding: const EdgeInsets.all(AppSpacing.screenPadding),
                              child: Text('Failed to load requests: $err', style: AppTypography.caption.copyWith(color: AppColors.error)),
                            ),
                            data: (requests) {
                              if (requests.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.screenPadding),
                                  child: Center(child: Text('No open requests nearby.', style: TextStyle(color: AppColors.textSecondary))),
                                );
                              }

                              return SizedBox(
                                height: 260, // Approximate height of RequestCard
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: requests.length,
                                  separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final request = requests[index];
                                    return SizedBox(
                                      width: 280, // Wider for request cards
                                      child: _RequestCard(
                                        request: request,
                                        onTap: () => context.go('/home/request/${request.id}'), // Navigates to a specific request page if one exists
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          if (value == 'all') {
            ref.read(selectedCategoryProvider.notifier).state = null;
          } else {
            ref.read(selectedCategoryProvider.notifier).state = value;
          }
        },
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
      ),
    );
  }
}

// Temporary internal widget until we make RequestCard reusable
class _RequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Fit content
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      CategoryConstants.getLabel(request.category),
                      style: AppTypography.labelSmall,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      'Needed',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                request.itemName,
                style: AppTypography.h4,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                request.description,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.currency_rupee, size: 14, color: AppColors.primary),
                      Text(
                        '${request.budgetPerDay?.toStringAsFixed(0) ?? '?'}',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '/day',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${request.durationDays ?? '?'} days',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
