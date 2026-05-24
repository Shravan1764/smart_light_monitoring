import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:light_sensor/light_sensor.dart';

/// Callback signature when light status changes after debounce.
typedef OnStableChange = void Function(bool isLightOn, double luxValue);

/// Core service that monitors the ambient light sensor with debounced state changes.
///
/// Listens to [LightSensor.luxStream], compares against a configurable
/// [thresholdLux], and only reports status changes that remain stable
/// for [debounceDuration] (default 5 seconds).
class SensorService {
  /// Lux threshold above which the light is considered "on".
  double thresholdLux;

  /// Duration the new status must remain stable before reporting.
  final Duration debounceDuration;

  /// Callback fired when a debounced, stable status change occurs.
  OnStableChange? onStableChange;

  /// Callback fired on every lux reading (for live UI updates).
  ValueChanged<double>? onLuxUpdate;

  // Internal state
  double _currentLux = 0.0;
  bool _lastReportedStatus = false;
  bool _isListening = false;
  Timer? _debounceTimer;
  StreamSubscription<int>? _luxSubscription;

  SensorService({
    this.thresholdLux = 50.0,
    this.debounceDuration = const Duration(seconds: 5),
    this.onStableChange,
    this.onLuxUpdate,
  });

  /// Current lux reading from the sensor.
  double get currentLux => _currentLux;

  /// Current light status based on threshold comparison.
  bool get isLightOn => _currentLux > thresholdLux;

  /// Whether the service is actively listening to the sensor.
  bool get isListening => _isListening;

  /// Last status that was reported to Firebase (after debounce).
  bool get lastReportedStatus => _lastReportedStatus;

  /// Check if the device has a light sensor available.
  static Future<bool> isSensorAvailable() async {
    try {
      return await LightSensor.hasSensor();
    } catch (e) {
      debugPrint('SensorService: Error checking sensor availability: $e');
      return false;
    }
  }

  /// Start listening to the light sensor stream.
  void startListening() {
    if (_isListening) return;
    _isListening = true;

    _luxSubscription = LightSensor.luxStream().listen(
      (int lux) {
        _currentLux = lux.toDouble();
        onLuxUpdate?.call(_currentLux);

        final newStatus = _currentLux > thresholdLux;
        if (newStatus != _lastReportedStatus) {
          _startDebounce(newStatus);
        } else {
          // Status reverted before debounce completed — cancel pending change
          _debounceTimer?.cancel();
        }
      },
      onError: (error) {
        debugPrint('SensorService: Sensor stream error: $error');
      },
    );

    debugPrint('SensorService: Started listening (threshold: $thresholdLux lux)');
  }

  /// Stop listening to the sensor and cancel any pending debounce.
  void stopListening() {
    _isListening = false;
    _debounceTimer?.cancel();
    _luxSubscription?.cancel();
    _luxSubscription = null;
    debugPrint('SensorService: Stopped listening');
  }

  /// Calibrate the threshold to the current ambient light level.
  ///
  /// Sets [thresholdLux] to the current reading, so values above this
  /// will be treated as "light on". Adds a small buffer (10%) to avoid
  /// jitter around the exact ambient level.
  double calibrate() {
    thresholdLux = _currentLux * 1.1; // 10% buffer above ambient
    if (thresholdLux < 5.0) thresholdLux = 5.0; // Minimum floor
    debugPrint('SensorService: Calibrated threshold to $thresholdLux lux');
    return thresholdLux;
  }

  /// Start a 5-second debounce timer for a status change.
  void _startDebounce(bool newStatus) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      // Verify the status is still the same after debounce
      final currentStatus = _currentLux > thresholdLux;
      if (currentStatus == newStatus) {
        _lastReportedStatus = newStatus;
        onStableChange?.call(newStatus, _currentLux);
        debugPrint(
          'SensorService: Stable change → isLightOn=$newStatus (lux=$_currentLux, threshold=$thresholdLux)',
        );
      }
    });
  }

  /// Clean up all resources.
  void dispose() {
    stopListening();
  }
}
