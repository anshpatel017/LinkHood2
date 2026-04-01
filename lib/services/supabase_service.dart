import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase global client accessor
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static String? get currentUserId => auth.currentUser?.id;

  static bool get isAuthenticated => auth.currentUser != null;

  /// Initialize Supabase — call in main.dart
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Get public URL for a file in a bucket
  static String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Upload a file to storage
  static Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String contentType = 'image/jpeg',
  }) async {
    await client.storage.from(bucket).uploadBinary(
      path,
      fileBytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );
    return getPublicUrl(bucket, path);
  }
}
