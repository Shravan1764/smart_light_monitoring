import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_light_monitoring/services/sensor_service.dart';
import 'package:smart_light_monitoring/services/firebase_service.dart';
import 'package:smart_light_monitoring/services/device_service.dart';

/// Manages the flutter_background_service for continuous sensor monitoring.
class BackgroundServiceManager {
  static const String _kRoomNameKey = 'smart_monitor_room_name';
  static const String _kThresholdKey = 'smart_monitor_threshold';
  static const String _kFcmTokenKey = 'smart_monitor_fcm_token';

  static bool get _supportsBackgroundService {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Initialize and configure the background service.
  static Future<bool> initialize() async {
    if (!_supportsBackgroundService) return false;
    final service = FlutterBackgroundService();

    try {
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: false,
          isForegroundMode: true,
          initialNotificationTitle: 'Smart Light Monitor',
          initialNotificationContent: 'Monitoring ambient light...',
          foregroundServiceNotificationId: 9001,
          foregroundServiceTypes: [AndroidForegroundType.dataSync],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
      );
      debugPrint('BackgroundServiceManager: Initialized');
      return true;
    } catch (e) {
      debugPrint('BackgroundServiceManager: Initialization failed: $e');
      return false;
    }
  }

  /// Start the background service.
  static Future<bool> startService() async {
    if (!_supportsBackgroundService) return false;
    final service = FlutterBackgroundService();
    try {
      // Ensure it's not already running
      if (await service.isRunning()) return true;

      await service.startService();
      debugPrint('BackgroundServiceManager: Service started');
      return true;
    } catch (e) {
      debugPrint('BackgroundServiceManager: Failed to start service: $e');
      return false;
    }
  }

  /// Stop the background service.
  static Future<void> stopService() async {
    if (!_supportsBackgroundService) return;
    final service = FlutterBackgroundService();
    try {
      service.invoke('stop');
      debugPrint('BackgroundServiceManager: Service stopped');
    } catch (e) {
      debugPrint('BackgroundServiceManager: Failed to stop service: $e');
    }
  }

  /// Check if the background service is running.
  static Future<bool> isRunning() async {
    if (!_supportsBackgroundService) return false;
    final service = FlutterBackgroundService();
    try {
      return await service.isRunning();
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveConfig({
    required String roomName,
    required double threshold,
    required String fcmToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRoomNameKey, roomName);
    await prefs.setDouble(_kThresholdKey, threshold);
    await prefs.setString(_kFcmTokenKey, fcmToken);
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase in this isolate if available.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('BackgroundService: Firebase init failed in isolate: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final roomName = prefs.getString('smart_monitor_room_name') ?? 'Unknown Room';
  final threshold = prefs.getDouble('smart_monitor_threshold') ?? 50.0;
  final deviceId = await DeviceService.getDeviceId();

  final firebaseService = FirebaseService();
  final sensorService = SensorService(thresholdLux: threshold);

  sensorService.onStableChange = (bool isLightOn, double luxValue) async {
    await firebaseService.updateLightStatus(
      deviceId: deviceId,
      isLightOn: isLightOn,
      luxValue: luxValue,
    );

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'Smart Light Monitor',
          content: '$roomName: Light is ${isLightOn ? "ON" : "OFF"} (${luxValue.toStringAsFixed(0)} lux)',
        );
      }
    }
  };

  sensorService.startListening();

  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: 'Smart Light Monitor',
          content: '$roomName: ${sensorService.currentLux.toStringAsFixed(0)} lux'
              ' | Light ${sensorService.isLightOn ? "ON" : "OFF"}',
        );
      }
    }

    service.invoke('lux_update', {
      'lux': sensorService.currentLux,
      'is_light_on': sensorService.isLightOn,
    });
  });

  service.on('stop').listen((event) {
    sensorService.dispose();
    service.stopSelf();
  });

  service.on('update_threshold').listen((event) {
    if (event != null && event['threshold'] != null) {
      sensorService.thresholdLux = (event['threshold'] as num).toDouble();
    }
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}
