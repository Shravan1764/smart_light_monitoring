import 'package:android_id/android_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a stable, unique device identifier.
///
/// Uses Android ID as primary, with a UUID fallback persisted in SharedPreferences.
class DeviceService {
  static const _kDeviceIdKey = 'smart_monitor_device_id';
  static String? _cachedId;

  /// Returns the unique device ID, creating and caching it on first call.
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    // Try loading from local storage first
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kDeviceIdKey);
    if (stored != null && stored.isNotEmpty) {
      _cachedId = stored;
      return _cachedId!;
    }

    // Try Android ID
    String? androidId;
    try {
      androidId = await const AndroidId().getId();
    } catch (_) {
      // Silently fall through to UUID fallback
    }

    if (androidId != null && androidId.isNotEmpty) {
      _cachedId = androidId;
    } else {
      // Generate a pseudo-UUID fallback
      _cachedId = _generateUuid();
    }

    // Persist for consistency across sessions
    await prefs.setString(_kDeviceIdKey, _cachedId!);
    return _cachedId!;
  }

  /// Simple pseudo-UUID generator (no external dependency needed).
  static String _generateUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'dev_${now.toRadixString(36)}_${_randomHex(8)}';
  }

  static String _randomHex(int length) {
    final chars = '0123456789abcdef';
    final buffer = StringBuffer();
    var seed = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < length; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      buffer.write(chars[seed % chars.length]);
    }
    return buffer.toString();
  }
}
