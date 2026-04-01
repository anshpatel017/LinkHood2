import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref _ref;
  
  NotificationService(this._ref);

  Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      print('Firebase not initialized yet. Skipping FCM setup.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          await _saveToken(token);
        }
        messaging.onTokenRefresh.listen(_saveToken);
      }
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    final user = await _ref.read(currentUserProvider.future);
    if (user != null) {
      final supabase = _ref.read(supabaseClientProvider);
      try {
        // Save FCM token to the backend
        await supabase.from('users').update({'fcm_token': token}).eq('id', user.id);
      } catch (e) {
        print('Failed to save FCM token: $e');
      }
    }
  }
}
