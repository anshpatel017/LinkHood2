import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

// Provides the Supabase Client
final supabaseClientProvider = Provider<supa.SupabaseClient>((ref) {
  return supa.Supabase.instance.client;
});

// Provides the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(client);
});

// Stream provider for the current logged-in user (reactive to auth changes)
final currentUserProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUserStream;
});

// Helper provider to check simple authentication status synchronously
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userAsy = ref.watch(currentUserProvider);
  return userAsy.valueOrNull != null;
});

// Provides an AuthController to manage auth actions
final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController {
  final AuthRepository _repo;
  AuthController(this._repo);

  Future<void> signInWithOtp(String email) => _repo.signInWithOtp(email);

  Future<void> signUpWithPassword(String name, String email, String password) =>
      _repo.signUpWithPassword(name, email, password);

  Future<bool> verifyOtp(String email, String token) =>
      _repo.verifyOtp(email, token);

  Future<void> setPassword(String password) => _repo.setPassword(password);

  Future<bool> signInWithPassword(String email, String password) =>
      _repo.signInWithPassword(email, password);

  Future<bool> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> signOut() => _repo.signOut();

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? areaName,
    double? latitude,
    double? longitude,
  }) => _repo.updateProfile(
    fullName: fullName,
    phone: phone,
    avatarUrl: avatarUrl,
    areaName: areaName,
    latitude: latitude,
    longitude: longitude,
  );

  Future<void> saveInventory(List<String> categories) =>
      _repo.saveInventory(categories);
}

// Controller specifically for Uploading Avatar
final avatarUploadControllerProvider = Provider<AvatarUploadController>((ref) {
  return AvatarUploadController(ref);
});

class AvatarUploadController {
  final Ref _ref;

  AvatarUploadController(this._ref);

  Future<void> uploadAvatar(String filePath) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user == null) throw Exception('Must be logged in to upload avatar');

    final file = File(filePath);
    final fileExt = filePath.split('.').last;
    final fileName = '${user.id}/avatar.$fileExt';

    final supabase = _ref.read(supabaseClientProvider);

    // Upload image
    await supabase.storage
        .from('avatars')
        .upload(
          fileName,
          file,
          fileOptions: const supa.FileOptions(upsert: true),
        );

    // Get public URL
    final url = supabase.storage.from('avatars').getPublicUrl(fileName);

    // Update profile
    await _ref.read(authControllerProvider).updateProfile(avatarUrl: url);

    // Refresh user data so the updated avatar is fetched
    _ref.invalidate(currentUserProvider);
  }
}
