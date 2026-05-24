import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_light_monitoring/services/sensor_service.dart';
import 'package:smart_light_monitoring/services/firebase_service.dart';
import 'package:smart_light_monitoring/services/device_service.dart';
import 'package:smart_light_monitoring/services/background_service.dart';

/// ChangeNotifier that wraps SensorService for the UI layer.
class SensorProvider extends ChangeNotifier {
  final SensorService _sensorService;
  final FirebaseService _firebaseService;

  // Persisted config
  String _roomName = '';
  String _fcmToken = '';
  String _deviceId = '';
  bool _isCalibrated = false;
  bool _isMonitoring = false;
  double _currentLux = 0.0;

  // SharedPreferences keys
  static const _kRoomNameKey = 'smart_monitor_room_name';
  static const _kThresholdKey = 'smart_monitor_threshold';
  static const _kCalibratedKey = 'smart_monitor_calibrated';

  SensorProvider({
    SensorService? sensorService,
    FirebaseService? firebaseService,
  })  : _sensorService = sensorService ?? SensorService(),
        _firebaseService = firebaseService ?? FirebaseService() {
    _sensorService.onLuxUpdate = _onLuxUpdate;
    _sensorService.onStableChange = _onStableChange;
    _loadPersistedConfig();
  }

  // ─── Getters ───────────────────────────────────────────────

  double get currentLux => _currentLux;
  bool get isLightOn => _currentLux > _sensorService.thresholdLux;
  double get thresholdLux => _sensorService.thresholdLux;
  String get roomName => _roomName;
  bool get isCalibrated => _isCalibrated;
  bool get isMonitoring => _isMonitoring;
  String get deviceId => _deviceId;

  // ─── Actions ───────────────────────────────────────────────

  Future<void> init(String? fcmToken) async {
    _fcmToken = fcmToken ?? '';
    _deviceId = await DeviceService.getDeviceId();
    notifyListeners();
  }

  Future<void> setRoomName(String name) async {
    _roomName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRoomNameKey, name);
    notifyListeners();
  }

  Future<void> setThreshold(double value) async {
    _sensorService.thresholdLux = value;
    _isCalibrated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kThresholdKey, value);
    await prefs.setBool(_kCalibratedKey, true);
    notifyListeners();
  }

  Future<double> calibrate() async {
    final threshold = _sensorService.calibrate();
    _isCalibrated = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kThresholdKey, threshold);
    await prefs.setBool(_kCalibratedKey, true);
    notifyListeners();
    return threshold;
  }

  void startSensorListening() {
    _sensorService.startListening();
    notifyListeners();
  }

  void stopSensorListening() {
    _sensorService.stopListening();
    notifyListeners();
  }

  Timer? _syncTimer;
  StreamSubscription? _commandSub;
  int _lastCommandTime = 0;
  
  final _commandStreamController = StreamController<Map<String, String>>.broadcast();
  Stream<Map<String, String>> get commandStream => _commandStreamController.stream;

  /// Start full monitoring: requests permissions and starts background service.
  Future<bool> startMonitoring() async {
    if (_roomName.isEmpty) return false;

    // 1. Request Notification Permission (Crucial for Android 13/14 Foreground Services)
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('SensorProvider: Notification permission denied');
      return false;
    }

    _isMonitoring = true;

    // 2. Write initial room data to Firebase
    await _syncToFirebase();
    
    // Listen for incoming commands (in-app alerts)
    _listenForCommands();

    // 3. Start a periodic sync every 5 seconds to keep the dashboard card fresh
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncToFirebase();
    });

    // 4. Save config for background isolate
    await BackgroundServiceManager.saveConfig(
      roomName: _roomName,
      threshold: _sensorService.thresholdLux,
      fcmToken: _fcmToken,
    );

    // 5. Initialize then start background service
    final initialized = await BackgroundServiceManager.initialize();
    if (!initialized) {
      _isMonitoring = false;
      _syncTimer?.cancel();
      _commandSub?.cancel();
      notifyListeners();
      return false;
    }

    final started = await BackgroundServiceManager.startService();
    if (!started) {
      _isMonitoring = false;
      _syncTimer?.cancel();
      _commandSub?.cancel();
      notifyListeners();
      return false;
    }

    notifyListeners();
    return true;
  }

  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _syncTimer?.cancel();
    _commandSub?.cancel();
    _sensorService.stopListening();
    await BackgroundServiceManager.stopService();
    notifyListeners();
  }

  // ─── Private ───────────────────────────────────────────────

  // ─── Private ───────────────────────────────────────────────

  void _listenForCommands() {
    _commandSub?.cancel();
    // Start listening to our own device's command node
    _commandSub = _firebaseService.roomRef(_deviceId).child('command').onValue.listen((event) {
      if (event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final timestamp = data['timestamp'] as int? ?? 0;
          
          if (_lastCommandTime == 0) {
            // Ignore old command on initial load
            _lastCommandTime = timestamp;
            return;
          }
          
          if (timestamp > _lastCommandTime) {
            _lastCommandTime = timestamp;
            _commandStreamController.add({
              'action': data['action']?.toString() ?? '',
              'sender': data['sender']?.toString() ?? 'Someone',
            });
          }
        } catch (e) {
          debugPrint('SensorProvider: Error parsing command data: $e');
        }
      }
    });
  }

  double _lastSyncedLux = -1.0;
  bool? _lastSyncedState;

  Future<void> _syncToFirebase() async {
    if (_deviceId.isEmpty || _roomName.isEmpty) return;
    
    // Optimization: Only sync if the state changed or lux changed by more than 3.0.
    // This prevents spamming the Realtime Database and causing the UI to stutter.
    if (_lastSyncedState != null && 
        _lastSyncedState == isLightOn && 
        (_currentLux - _lastSyncedLux).abs() < 3.0) {
      return; 
    }

    try {
      await _firebaseService.updateRoom(
        deviceId: _deviceId,
        roomName: _roomName,
        isLightOn: isLightOn,
        luxValue: _currentLux,
        fcmToken: _fcmToken,
      );
      _lastSyncedLux = _currentLux;
      _lastSyncedState = isLightOn;
    } catch (e) {
      debugPrint('SensorProvider: Sync failed: $e');
    }
  }

  Timer? _uiThrottleTimer;

  void _onLuxUpdate(double lux) {
    // Always store the absolute latest value immediately
    _currentLux = lux;
    
    // Optimization: Throttle UI rebuilds to a max of 5 frames per second using a Timer.
    // This guarantees the absolute final value is ALWAYS pushed to the UI, 
    // unlike the previous time-diff approach which dropped the final frame.
    if (_uiThrottleTimer?.isActive ?? false) return;
    
    _uiThrottleTimer = Timer(const Duration(milliseconds: 200), () {
      notifyListeners();
    });
  }

  void _onStableChange(bool isLightOn, double luxValue) async {
    if (_deviceId.isEmpty || _roomName.isEmpty) return;

    await _firebaseService.updateLightStatus(
      deviceId: _deviceId,
      isLightOn: isLightOn,
      luxValue: luxValue,
    );
    _lastSyncedLux = luxValue;
    _lastSyncedState = isLightOn;
  }

  Future<void> _loadPersistedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _roomName = prefs.getString(_kRoomNameKey) ?? '';
    _isCalibrated = prefs.getBool(_kCalibratedKey) ?? false;
    final threshold = prefs.getDouble(_kThresholdKey);
    if (threshold != null) {
      _sensorService.thresholdLux = threshold;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _commandSub?.cancel();
    _commandStreamController.close();
    _sensorService.dispose();
    super.dispose();
  }
}
