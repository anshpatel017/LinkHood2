import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/request.dart';
import '../../domain/repositories/request_repository.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../../../services/location_service.dart';

final requestRepositoryProvider = Provider<RequestRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RequestRepositoryImpl(client);
});

/// Nearby open requests (shown on home page)
final nearbyRequestsProvider = FutureProvider<List<ItemRequest>>((ref) async {
  final repo = ref.watch(requestRepositoryProvider);
  try {
    final position = await LocationService.getCurrentPosition();
    return repo.getNearbyRequests(
      lat: position.latitude,
      lng: position.longitude,
    );
  } catch (_) {
    // Fallback if location unavailable
    return repo.getNearbyRequests(lat: 0, lng: 0);
  }
});

/// Current user's own requests
final myRequestsProvider = FutureProvider<List<ItemRequest>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  final repo = ref.watch(requestRepositoryProvider);
  return repo.getMyRequests(user.id);
});

final postRequestControllerProvider = Provider<PostRequestController>((ref) {
  return PostRequestController(ref);
});

class PostRequestController {
  final Ref _ref;

  PostRequestController(this._ref);

  Future<void> postRequest({
    required String category,
    required String itemName,
    required String description,
    double? budgetPerDay,
    int? durationDays,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user == null) throw Exception('Must be logged in to post request');

    final position = await LocationService.getCurrentPosition();

    final repo = _ref.read(requestRepositoryProvider);
    await repo.createRequest(
      category: category,
      itemName: itemName,
      description: description,
      budgetPerDay: budgetPerDay,
      durationDays: durationDays,
      startDate: startDate,
      endDate: endDate,
      lat: position.latitude,
      lng: position.longitude,
    );
  }
}
