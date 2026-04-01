import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../services/location_service.dart';
import '../providers/listing_provider.dart';
import '../../data/models/listing_model.dart';
import 'package:image_picker/image_picker.dart';

// Provides the AddListingController
final addListingControllerProvider = Provider<AddListingController>((ref) {
  return AddListingController(ref);
});

class AddListingController {
  final Ref _ref;

  AddListingController(this._ref);

  Future<void> createListing({
    required String title,
    required String description,
    required String category,
    required double pricePerDay,
    required double depositAmount,
    required List<XFile> images,
    bool isInstant = false,
  }) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user == null) {
      throw Exception('You must be logged in to create a listing.');
    }

    // 1. Get GPS Location
    double lat;
    double lng;
    final position = await LocationService.getCurrentPosition();
    lat = position.latitude;
    lng = position.longitude;

    // 2. Upload Images to Supabase Storage
    final supabase = _ref.read(supabaseClientProvider);
    final List<String> imageUrls = [];
    final uuid = const Uuid();

    for (var image in images) {
      // Web-safe image upload
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last.isNotEmpty ? image.name.split('.').last : 'jpg';
      final fileName = '${user.id}/${uuid.v4()}.$fileExt';
      
      await supabase.storage.from('listings').uploadBinary(fileName, bytes);
      
      final imageUrl = supabase.storage.from('listings').getPublicUrl(fileName);
      imageUrls.add(imageUrl);
    }

    // 3. Save to Database
    final repo = _ref.read(listingRepositoryProvider);
    final listingId = uuid.v4();
    
    final newListing = ListingModel(
      id: listingId,
      ownerId: user.id,
      title: title,
      description: description,
      category: category,
      pricePerDay: pricePerDay,
      depositAmount: depositAmount,
      imageUrls: imageUrls,
      isAvailable: true,
      isInstant: isInstant,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      // location handle inside repository implementation
    );

    await repo.createListing(newListing, lat, lng);
    
    // Refresh nearby listings after adding
    _ref.invalidate(nearbyListingsProvider);
  }
}
