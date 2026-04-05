import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final supa.SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  String _mapAuthErrorMessage(String message) {
    final normalized = message.toLowerCase();

    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Please verify your email first.';
    }
    if (normalized.contains('rate limit') || normalized.contains('429')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (normalized.contains('failed to send email') ||
        normalized.contains('email provider') ||
        normalized.contains('smtp') ||
        normalized.contains('unexpected_failure')) {
      return 'Verification service is temporarily unavailable. Please try again shortly.';
    }
    if (normalized.contains('500') || normalized.contains('internal')) {
      return 'Server is temporarily unavailable. Please try again shortly.';
    }
    if (normalized.contains('400') || normalized.contains('bad request')) {
      return 'Request could not be processed. Please check your input and try again.';
    }

    return message;
  }

  @override
  Stream<User?> get currentUserStream {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) return null;
      return await getCurrentUser();
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final supaUser = _supabase.auth.currentUser;
      if (supaUser == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', supaUser.id)
          .maybeSingle();

      if (response == null) {
        // User authenticated but no profile row yet — create one
        final newUser = UserModel(
          id: supaUser.id,
          email: supaUser.email ?? '',
          fullName: '',
          createdAt: DateTime.now(),
        );
        await _supabase.from('users').insert(newUser.toJson());
        return newUser;
      }

      return UserModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<void> signInWithOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: true);
    } on supa.AuthException catch (e) {
      throw AuthException(_mapAuthErrorMessage(e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        _mapAuthErrorMessage('Failed to send verification code: $e'),
      );
    }
  }

  @override
  Future<bool> verifyOtp(String email, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: supa.OtpType.email,
      );
      if (response.user == null) {
        throw AuthException('Verification failed. Please try again.');
      }
      return !(await isProfileComplete());
    } on supa.AuthException catch (e) {
      throw AuthException(_mapAuthErrorMessage(e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_mapAuthErrorMessage('OTP verification failed: $e'));
    }
  }

  @override
  Future<void> setPassword(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw AuthException('Not authenticated');
      await _supabase.auth.updateUser(supa.UserAttributes(password: password));
    } on supa.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to set password: $e');
    }
  }

  @override
  Future<void> signUpWithPassword(
      String name, String email, String password) async {
    try {
      // Use Edge Function to create user (bypasses email confirmation)
      final response = await _supabase.functions.invoke(
        'signup',
        body: {
          'email': email,
          'password': password,
          'full_name': name,
        },
      );

      if (response.status != 200) {
        final error = response.data?['error'] ?? 'Sign up failed';
        throw AuthException(_mapAuthErrorMessage(error.toString()));
      }

      // Profile row is auto-created by database trigger
    } on supa.FunctionException catch (e) {
      throw AuthException(_mapAuthErrorMessage(e.toString()));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_mapAuthErrorMessage('Sign up failed: $e'));
    }
  }

  @override
  Future<bool> signInWithPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw AuthException('Login failed. Check your credentials.');
      }
      return !(await isProfileComplete());
    } on supa.AuthException catch (e) {
      throw AuthException(_mapAuthErrorMessage(e.message));
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_mapAuthErrorMessage('Login failed: $e'));
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    throw AuthException(
      'Google sign-in is temporarily disabled. Use email and verification code.',
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e');
    }
  }

  @override
  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? areaName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw AuthException('Not authenticated');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (areaName != null) updates['area_name'] = areaName;
      if (latitude != null && longitude != null) {
        updates['location'] = 'POINT($longitude $latitude)';
      }

      await _supabase.from('users').update(updates).eq('id', userId);
    } catch (e) {
      throw ServerException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> saveInventory(List<String> categories) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw AuthException('Not authenticated');

      await _supabase.from('user_inventory').delete().eq('user_id', userId);
      if (categories.isNotEmpty) {
        await _supabase
            .from('user_inventory')
            .insert(
              categories
                  .map((c) => {'user_id': userId, 'category': c})
                  .toList(),
            );
      }
    } catch (e) {
      throw ServerException('Failed to save inventory: $e');
    }
  }

  @override
  Future<bool> isProfileComplete() async {
    final user = await getCurrentUser();
    if (user == null) return false;
    return user.fullName.isNotEmpty;
  }
}
