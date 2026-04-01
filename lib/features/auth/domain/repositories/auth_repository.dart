import '../entities/user.dart';

/// Repository interface for Authentication and User Profile
abstract class AuthRepository {
  /// Stream of the current user's profile. Emits null if unauthenticated.
  Stream<User?> get currentUserStream;

  /// Gets the currently logged-in user profile if it exists.
  Future<User?> getCurrentUser();

  /// Sends a 6-digit OTP to the given email for sign-up verification.
  /// Creates the user in Supabase Auth if they don't exist yet.
  Future<void> signInWithOtp(String email);

  /// Verifies the OTP code sent to the user's email.
  /// Returns [true] if the user still needs onboarding.
  Future<bool> verifyOtp(String email, String token);

  /// Sets the user's password after OTP verification.
  Future<void> setPassword(String password);

  /// Signs in with email + password. Returns [true] if onboarding is needed.
  Future<bool> signInWithPassword(String email, String password);

  /// Signs in with Google OAuth. Returns [true] if onboarding is needed.
  Future<bool> signInWithGoogle();

  /// Signs the user out.
  Future<void> signOut();

  /// Updates the user's profile details.
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? areaName,
    double? latitude,
    double? longitude,
  });

  /// Saves the categories of items the user owns.
  Future<void> saveInventory(List<String> categories);

  /// Checks if the user has completed their profile and inventory setup.
  Future<bool> isProfileComplete();
}
