import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Make sure this import is here
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:smart_light_monitoring/app.dart';
import 'package:smart_light_monitoring/providers/sensor_provider.dart';
import 'package:smart_light_monitoring/providers/rooms_provider.dart';
import 'package:smart_light_monitoring/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // MUST AWAIT FIREBASE FIRST
  var firebaseReady = false;
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    firebaseReady = true;
  } catch (e) {
    debugPrint('main: Firebase initialization failed: $e');
  }

  // Create providers
  final sensorProvider = SensorProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sensorProvider),
        ChangeNotifierProvider(create: (_) => RoomsProvider()),
      ],
      child: const SmartMonitorApp(),
    ),
  );

  // Initialize other integrations after first frame.
  unawaited(_bootstrapServices(sensorProvider, firebaseReady));
}

Future<void> _bootstrapServices(SensorProvider sensorProvider, bool firebaseReady) async {

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  String? fcmToken;
  if (firebaseReady && !kIsWeb) {
    try {
      final notificationService = NotificationService();
      fcmToken =
      await notificationService.initialize().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('main: Notification initialization failed: $e');
    }
  }

  await sensorProvider.init(fcmToken);
}
