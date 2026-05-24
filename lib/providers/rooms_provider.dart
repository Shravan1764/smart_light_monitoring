import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_light_monitoring/models/room_data.dart';
import 'package:smart_light_monitoring/services/firebase_service.dart';

/// ChangeNotifier that provides a reactive list of all rooms
/// from the Firebase Realtime Database `/rooms` node.
class RoomsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  List<RoomData> _rooms = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<DatabaseEvent>? _subscription;

  RoomsProvider({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService() {
    _startListening();
  }

  // ─── Getters ───────────────────────────────────────────────

  List<RoomData> get rooms => List.unmodifiable(_rooms);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeRoomCount => _rooms.where((r) => r.isLightOn).length;

  /// Get a specific room by device ID.
  RoomData? getRoomById(String deviceId) {
    try {
      return _rooms.firstWhere((r) => r.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }

  // ─── Actions ───────────────────────────────────────────────

  FirebaseService get firebaseService => _firebaseService;

  /// Manually refresh rooms data.
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    // The stream will automatically provide the latest data
  }

  // ─── Private ───────────────────────────────────────────────

  void _startListening() {
    _subscription = _firebaseService.roomsStream().listen(
      (DatabaseEvent event) {
        _isLoading = false;
        _error = null;

        if (event.snapshot.value == null) {
          _rooms = [];
          notifyListeners();
          return;
        }

        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          _rooms = data.entries.map((entry) {
            final deviceId = entry.key as String;
            final roomJson = entry.value as Map<dynamic, dynamic>;
            return RoomData.fromJson(deviceId, roomJson);
          }).toList();

          // Sort by room name for consistent display order
          _rooms.sort((a, b) => a.roomName.compareTo(b.roomName));

          debugPrint('RoomsProvider: Updated ${_rooms.length} rooms');
        } catch (e) {
          debugPrint('RoomsProvider: Error parsing rooms: $e');
          _error = 'Error loading rooms';
        }

        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = 'Connection error: $error';
        debugPrint('RoomsProvider: Stream error: $error');
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
