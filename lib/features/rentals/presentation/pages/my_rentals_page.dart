import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../providers/rental_provider.dart';
import '../widgets/rental_card.dart';

class MyRentalsPage extends ConsumerStatefulWidget {
  const MyRentalsPage({super.key});

  @override
  ConsumerState<MyRentalsPage> createState() => _MyRentalsPageState();
}

class _MyRentalsPageState extends ConsumerState<MyRentalsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borrowedAsync = ref.watch(myBorrowedRentalsProvider);
    final lentAsync = ref.watch(myLentRentalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'As Borrower'),
            Tab(text: 'As Lender'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Borrowed items
          borrowedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (rentals) {
              if (rentals.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.shopping_bag_outlined,
                  title: 'No rentals yet',
                  subtitle: 'Items you rent from neighbors will show up here.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  return RentalCard(rental: rentals[index], isLender: false);
                },
              );
            },
          ),
          
          // Lent out items
          lentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (rentals) {
              if (rentals.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.storefront_outlined,
                  title: 'No items lent out',
                  subtitle: 'When someone rents your items, they appear here.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  return RentalCard(rental: rentals[index], isLender: true);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
