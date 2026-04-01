import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listing_repository.dart';
import '../models/listing_model.dart';

class ListingRepositoryImpl implements ListingRepository {
  final supa.SupabaseClient _supabase;

  ListingRepositoryImpl(this._supabase);

  @override
  Future<List<Listing>> searchNearbyListings({
    required double lat,
    required double lng,
    required double radiusMeters,
    String? category,
  }) async {
    try {
      // Call the PostGIS spatial RPC
      var query = _supabase.rpc(
        'get_ranked_nearby_listings',
        params: {
          'lat': lat,
          'lng': lng,
          'radius_meters': radiusMeters,
        },
      );

      final response = await query;

      final List<dynamic> data = response as List<dynamic>;
      
      var listings = data
          .map((json) => ListingModel.fromRankedJson(json as Map<String, dynamic>))
          .toList();

      if (category != null && category.isNotEmpty) {
        listings = listings.where((l) => l.category == category).toList();
      }

      return listings;
    } catch (e) {
      throw ServerException('Failed to fetch nearby listings: $e');
    }
  }

  @override
  Future<Listing> getListingById(String id) async {
    try {
      final response = await _supabase
          .from('listings')
          .select('''
            *,
            users:owner_id (
              full_name,
              avatar_url,
              rating_avg
            )
          ''')
          .eq('id', id)
          .single();

      // Transform joined user data to fit model expectations
      final Map<String, dynamic> json = Map.from(response);
      if (json['users'] != null) {
        final user = json['users'] as Map<String, dynamic>;
        json['owner_name'] = user['full_name'];
        json['owner_avatar'] = user['avatar_url'];
        json['owner_rating'] = user['rating_avg'];
      }

      return ListingModel.fromJson(json);
    } catch (e) {
      throw ServerException('Failed to fetch listing: $e');
    }
  }

  @override
  Future<List<Listing>> getMyListings(String userId) async {
    try {
      final response = await _supabase
          .from('listings')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => ListingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch user listings: $e');
    }
  }

  @override
  Future<Listing> createListing(Listing listing, double lat, double lng) async {
    try {
      final model = listing as ListingModel;
      final response = await _supabase
          .from('listings')
          .insert(model.toCreateJson(lat, lng))
          .select()
          .single();
      
      return ListingModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create listing: $e');
    }
  }

  @override
  Future<Listing> updateListing(Listing listing) async {
    try {
      final model = listing as ListingModel;
      final response = await _supabase
          .from('listings')
          .update(model.toJson())
          .eq('id', listing.id)
          .select()
          .single();
      
      return ListingModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update listing: $e');
    }
  }

  @override
  Future<void> deleteListing(String id) async {
    try {
      await _supabase.from('listings').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete listing: $e');
    }
  }
}
