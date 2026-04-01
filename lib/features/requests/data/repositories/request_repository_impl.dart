import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/request.dart';
import '../../domain/entities/request_response.dart';
import '../../domain/repositories/request_repository.dart';
import '../models/request_model.dart';
import '../models/request_response_model.dart';

class RequestRepositoryImpl implements RequestRepository {
  final supa.SupabaseClient _supabase;

  RequestRepositoryImpl(this._supabase);

  @override
  Future<ItemRequest> createRequest({
    required String category,
    required String itemName,
    required String description,
    double? budgetPerDay,
    int? durationDays,
    DateTime? startDate,
    DateTime? endDate,
    required double lat,
    required double lng,
  }) async {
    try {
      final model = ItemRequestModel(
        id: '', // placeholder — not sent to DB
        requesterId: '', // placeholder — not sent to DB (set by auth.uid())
        category: category,
        itemName: itemName,
        description: description,
        budgetPerDay: budgetPerDay,
        durationDays: durationDays,
        startDate: startDate,
        endDate: endDate,
        status: 'open',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('requests')
          .insert(model.toCreateJson(lat, lng))
          .select()
          .single();

      // Try invoking edge function for broadcasting notification
      // (Gracefully handle failures since the request is already created)
      try {
        await _supabase.functions.invoke(
          'broadcast_request',
          body: {'request_id': response['id']},
        );
      } catch (e) {
        // Ignored. Notifications fail silently to avoid blocking the user flow
      }

      return ItemRequestModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to post request: $e');
    }
  }

  @override
  Future<List<ItemRequest>> getNearbyRequests({
    required double lat,
    required double lng,
    double radiusMeters = 500,
  }) async {
    try {
      // Fetch open requests ordered by most recent
      final response = await _supabase
          .from('requests')
          .select()
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => ItemRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch nearby requests: $e');
    }
  }

  @override
  Future<List<ItemRequest>> getMyRequests(String userId) async {
    try {
      final response = await _supabase
          .from('requests')
          .select()
          .eq('requester_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ItemRequestModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch your requests: $e');
    }
  }

  @override
  Future<void> offerListingToRequest({
    required String requestId,
    required String listingId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw ServerException('Not authenticated');

      await _supabase.from('request_responses').insert({
        'request_id': requestId,
        'responder_id': userId,
        'listing_id': listingId,
        'status': 'pending',
      });
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to offer item: $e');
    }
  }

  @override
  Future<List<RequestResponse>> getRequestResponses(String requestId) async {
    try {
      final response = await _supabase
          .from('request_responses')
          .select('*, users:responder_id(full_name, avatar_url)')
          .eq('request_id', requestId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) =>
              RequestResponseModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch responses: $e');
    }
  }

  @override
  Future<void> updateResponseStatus(
      String responseId, String newStatus) async {
    try {
      await _supabase
          .from('request_responses')
          .update({'status': newStatus})
          .eq('id', responseId);
    } catch (e) {
      throw ServerException('Failed to update response status: $e');
    }
  }
}
