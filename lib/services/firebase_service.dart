import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Service for all Firebase Realtime Database operations.
///
/// Handles reading/writing room data and sending nudge notifications
/// via FCM HTTP API or Cloud Function endpoint.
class FirebaseService {
  // Prefer dart-define for production:
  // --dart-define=FIREBASE_DATABASE_URL=https://<your-db>.firebasedatabase.app
  static const String _databaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: '',
  );

  final DatabaseReference _db = (_databaseUrl.isNotEmpty
          ? FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: _databaseUrl,
            )
          : FirebaseDatabase.instance)
      .ref();

  /// Reference to the `/rooms` node.
  DatabaseReference get _roomsRef => _db.child('rooms');

  /// Reference to a specific room by device ID.
  DatabaseReference roomRef(String deviceId) => _roomsRef.child(deviceId);

  /// Update or create a room entry in Firebase RTDB.
  ///
  /// Uses [ServerValue.timestamp] for the `last_updated` field to ensure
  /// consistent server-side timestamps.
  Future<void> updateRoom({
    required String deviceId,
    required String roomName,
    required bool isLightOn,
    required double luxValue,
    required String fcmToken,
  }) async {
    try {
      final payload = <String, Object?>{
        'room_name': roomName,
        'is_light_on': isLightOn,
        'lux_value': luxValue,
        'last_updated': ServerValue.timestamp,
      };
      if (fcmToken.isNotEmpty) {
        payload['fcm_token'] = fcmToken;
      }

      await roomRef(deviceId).update(payload);
      debugPrint('FirebaseService: Updated room $deviceId → lightOn=$isLightOn, lux=$luxValue');
    } catch (e) {
      debugPrint('FirebaseService: Error updating room: $e');
      rethrow;
    }
  }

  /// Update only the light status and lux value (used by background service).
  Future<void> updateLightStatus({
    required String deviceId,
    required bool isLightOn,
    required double luxValue,
  }) async {
    try {
      await roomRef(deviceId).update({
        'is_light_on': isLightOn,
        'lux_value': luxValue,
        'last_updated': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('FirebaseService: Error updating light status: $e');
    }
  }

  /// Update the FCM token for a device.
  Future<void> updateFcmToken({
    required String deviceId,
    required String fcmToken,
  }) async {
    if (fcmToken.isEmpty) return;
    try {
      await roomRef(deviceId).update({
        'fcm_token': fcmToken,
      });
    } catch (e) {
      debugPrint('FirebaseService: Error updating FCM token: $e');
    }
  }

  /// Stream all rooms from the `/rooms` node.
  ///
  /// Returns a stream of [DatabaseEvent] that fires on every change
  /// to any room in the database.
  Stream<DatabaseEvent> roomsStream() {
    return _roomsRef.onValue;
  }

  /// Stream a single room by device ID.
  Stream<DatabaseEvent> singleRoomStream(String deviceId) {
    return roomRef(deviceId).onValue;
  }

  /// Delete a room entry from Firebase.
  Future<void> deleteRoom(String deviceId) async {
    try {
      await roomRef(deviceId).remove();
      debugPrint('FirebaseService: Deleted room $deviceId');
    } catch (e) {
      debugPrint('FirebaseService: Error deleting room: $e');
    }
  }

  /// Send a command to a specific device via RTDB
  Future<bool> sendCommand({
    required String targetDeviceId,
    required String command,
    required String senderRoomName,
  }) async {
    try {
      await roomRef(targetDeviceId).child('command').set({
        'action': command,
        'sender': senderRoomName,
        'timestamp': ServerValue.timestamp,
      });
      debugPrint('FirebaseService: Command sent successfully');
      return true;
    } catch (e) {
      debugPrint('FirebaseService: Error sending command: $e');
      return false;
    }
  }
}
