import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_light_monitoring/services/device_service.dart';
import 'package:smart_light_monitoring/services/firebase_service.dart';

/// Handles Firebase Cloud Messaging setup, token management,
/// and incoming notification handling.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Initialize FCM: request permissions, get token, and register handlers.
  Future<String?> initialize() async {
    // Request notification permissions (Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint(
      'NotificationService: Permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('NotificationService: Notifications denied by user');
      return null;
    }

    // Get FCM token
    final token = await _messaging.getToken();
    debugPrint('NotificationService: FCM Token: $token');

    if (token != null) {
      // Save token to Firebase for this device
      final deviceId = await DeviceService.getDeviceId();
      await _firebaseService.updateFcmToken(
        deviceId: deviceId,
        fcmToken: token,
      );
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('NotificationService: Token refreshed: $newToken');
      final deviceId = await DeviceService.getDeviceId();
      await _firebaseService.updateFcmToken(
        deviceId: deviceId,
        fcmToken: newToken,
      );
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    return token;
  }

  /// Handle incoming message while app is in foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      'NotificationService: Foreground message: ${message.notification?.title}',
    );
    // The notification will automatically show as a heads-up notification
    // on Android if the channel importance is high enough.
    // For custom UI handling, you could use a local notification package here.
  }

  /// Handle when user taps a notification (from background or terminated).
  void _handleMessageTap(RemoteMessage message) {
    debugPrint(
      'NotificationService: Message tap: ${message.notification?.title}',
    );
    // Navigate to dashboard or specific room — can be extended with
    // a navigation callback if needed.
  }

  /// Get the current FCM token.
  Future<String?> getToken() => _messaging.getToken();
}

/// Top-level function for handling background messages.
///
/// Must be a top-level function (not a class method) for Firebase.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase may already be initialized in this isolate.
  }
  debugPrint(
    'NotificationService: Background message: ${message.notification?.title}',
  );
}
