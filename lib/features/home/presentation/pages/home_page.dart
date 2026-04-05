import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
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
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
      // Refresh listings after permission granted
      ref.invalidate(nearbyListingsProvider);
    }
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
        title: Row(
          children: [
            // LinkHood Logo (3 dots representation)
            SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                children: [
                  Positioned(
                    top: 2,
                    left: 8,
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LinkHood',
              style: AppTypography.h2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => context.go('/add-listing'),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
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
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                filled: true,
                fillColor: AppColors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Category Filter Tabs
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              children: [
                _buildCategoryChip('all', 'All', selectedCategory == null),
                ...CategoryConstants.allCategories.map(
                  (cat) => _buildCategoryChip(
                    cat,
                    CategoryConstants.getLabel(cat),
                    selectedCategory == cat,
                  ),
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
                  filtered = filtered
                      .where(
                        (l) => l.title.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Nearby Items
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.md,
                        ),
                        child: Text('Nearby Items', style: AppTypography.h3),
                      ),
                      SizedBox(
                        height: 320, // Taller so image is clearly visible
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  'No items nearby matching criteria.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screenPadding,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return SizedBox(
                                    width:
                                        280, // Fixed width for horizontal scrolling
                                    child: ListingCard(
                                      listing: item,
                                      onTap: () =>
                                          context.go('/home/item/${item.id}'),
                                    ),
                                  );
                                },
                              ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Section 2: Nearby Requests
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text('Nearby Requests', style: AppTypography.h3),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final requestsAsync = ref.watch(
                            nearbyRequestsProvider,
                          );
                          return requestsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, stack) => Padding(
                              padding: const EdgeInsets.all(
                                AppSpacing.screenPadding,
                              ),
                              child: Text(
                                'Failed to load requests: $err',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                            data: (requests) {
                              if (requests.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(
                                    AppSpacing.screenPadding,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No open requests nearby.',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return SizedBox(
                                height:
                                    260, // Approximate height of RequestCard
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.screenPadding,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: requests.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: AppSpacing.md),
                                  itemBuilder: (context, index) {
                                    final request = requests[index];
                                    return SizedBox(
                                      width: 280, // Wider for request cards
                                      child: _RequestCard(
                                        request: request,
                                        onTap: () => context.go(
                                          '/home/request/${request.id}',
                                        ), // Navigates to a specific request page if one exists
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height: 120,
                      ), // Clearance for floating bottom navbar
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
        showCheckmark: false,
        onSelected: (_) {
          if (value == 'all') {
            ref.read(selectedCategoryProvider.notifier).state = null;
          } else {
            ref.read(selectedCategoryProvider.notifier).state = value;
          }
        },
        backgroundColor: AppColors.surfaceContainer,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: BorderSide.none,
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onTap;

  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      CategoryConstants.getLabel(
                        request.category,
                      ).toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${request.budgetPerDay?.toStringAsFixed(0) ?? '?'}',
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'BUDGET / DAY',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCE54), // Solid yellow
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Needed',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                request.itemName,
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                request.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Progress bar
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.35, // Static representation for the mock
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF286C34,
                      ), // AppColors.statusAccent green
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${request.durationDays ?? '?'} Days Left',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '3 Offers', // Static representation as per UI spec
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
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
