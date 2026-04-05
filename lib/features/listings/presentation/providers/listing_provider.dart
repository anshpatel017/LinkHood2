import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../services/location_service.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../../data/repositories/listing_repository_impl.dart';

// Provides the ListingRepository
final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ListingRepositoryImpl(client);
});

// Provides the currently selected category filter in Home
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Provides the search radius (default 50km)
final searchRadiusProvider = StateProvider<double>((ref) => 50000.0);

// Provides the nearby listings feed
// It reacts to category filter, search radius, and current user
final nearbyListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final repo = ref.watch(listingRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final radius = ref.watch(searchRadiusProvider);

  double? lat;
  double? lng;

  try {
    // Prefer recent GPS location
    final position =
        await LocationService.getLastKnownPosition() ??
        await LocationService.getCurrentPosition();
    lat = position.latitude;
    lng = position.longitude;
  } catch (e) {
    // If location is denied or unavailable on web emulator, fallback to the test location
    // so the items created by the user consistently show up.
    // Nadiad coordinates based on the generated DB listings
    lat = 22.695;
    lng = 72.862;
  }

  return repo.searchNearbyListings(
    lat: lat,
    lng: lng,
    radiusMeters: radius,
    category: category,
  );
});

// Provides the user's own listings
final myListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final repo = ref.watch(listingRepositoryProvider);
  return repo.getMyListings(user.id);
});

// Provides a specific listing by ID
final listingDetailProvider = FutureProvider.family<Listing, String>((
  ref,
  id,
) async {
  final repo = ref.watch(listingRepositoryProvider);
  return repo.getListingById(id);
});

// Delete listing notifier
final deleteListingProvider = FutureProvider.family<void, String>((
  ref,
  id,
) async {
  final repo = ref.watch(listingRepositoryProvider);
  await repo.deleteListing(id);
  // Invalidate my listings to refresh the list
  ref.invalidate(myListingsProvider);
  ref.invalidate(nearbyListingsProvider);
});
