/// Data model representing a room/device in the Smart Light Monitor system.
///
/// Maps to the Firebase RTDB schema at `/rooms/{deviceId}`.
class RoomData {
  final String deviceId;
  final String roomName;
  final bool isLightOn;
  final double luxValue;
  final String fcmToken;
  final int lastUpdated;

  const RoomData({
    required this.deviceId,
    required this.roomName,
    required this.isLightOn,
    required this.luxValue,
    required this.fcmToken,
    required this.lastUpdated,
  });

  /// Construct from Firebase RTDB snapshot value.
  factory RoomData.fromJson(String deviceId, Map<dynamic, dynamic> json) {
    return RoomData(
      deviceId: deviceId,
      roomName: json['room_name'] as String? ?? 'Unknown Room',
      isLightOn: json['is_light_on'] as bool? ?? false,
      luxValue: (json['lux_value'] as num?)?.toDouble() ?? 0.0,
      fcmToken: json['fcm_token'] as String? ?? '',
      lastUpdated: json['last_updated'] as int? ?? 0,
    );
  }

  /// Serialize to Firebase RTDB-compatible JSON.
  Map<String, dynamic> toJson() {
    return {
      'room_name': roomName,
      'is_light_on': isLightOn,
      'lux_value': luxValue,
      'fcm_token': fcmToken,
      'last_updated': lastUpdated,
    };
  }

  /// Create a copy with updated fields.
  RoomData copyWith({
    String? roomName,
    bool? isLightOn,
    double? luxValue,
    String? fcmToken,
    int? lastUpdated,
  }) {
    return RoomData(
      deviceId: deviceId,
      roomName: roomName ?? this.roomName,
      isLightOn: isLightOn ?? this.isLightOn,
      luxValue: luxValue ?? this.luxValue,
      fcmToken: fcmToken ?? this.fcmToken,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Human-readable relative time string from the last update timestamp.
  String get lastUpdatedRelative {
    if (lastUpdated == 0) return 'Never';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = Duration(milliseconds: now - lastUpdated);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  String toString() =>
      'RoomData(deviceId: $deviceId, room: $roomName, lightOn: $isLightOn, lux: $luxValue)';
}
