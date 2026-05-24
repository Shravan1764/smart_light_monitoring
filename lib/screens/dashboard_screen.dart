import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light_monitoring/models/room_data.dart';
import 'package:smart_light_monitoring/providers/rooms_provider.dart';
import 'package:smart_light_monitoring/providers/sensor_provider.dart';
import 'package:smart_light_monitoring/theme/app_theme.dart';
import 'package:smart_light_monitoring/widgets/room_card.dart';
import 'package:smart_light_monitoring/screens/setup_screen.dart';

/// Main dashboard displaying all active rooms from Firebase RTDB.
///
/// Uses a StreamBuilder pattern (via RoomsProvider) to reactively
/// display room cards in a grid layout.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription? _commandSub;

  @override
  void initState() {
    super.initState();
    // Delay setting up the listener until the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sensorProvider = context.read<SensorProvider>();
      _commandSub = sensorProvider.commandStream.listen((commandData) {
        if (!mounted) return;
        final action = commandData['action'];
        final sender = commandData['sender'];
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  action == 'TURN_ON' ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: action == 'TURN_ON' ? AppTheme.lightOn : AppTheme.lightOff,
                ),
                const SizedBox(width: 10),
                const Text('Light Request', style: TextStyle(color: AppTheme.textPrimary)),
              ],
            ),
            content: Text(
              action == 'TURN_ON' 
                  ? '$sender is requesting you to turn ON your lights!'
                  : '$sender is requesting you to turn OFF your lights!',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss', style: TextStyle(color: AppTheme.accent)),
              ),
            ],
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _commandSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorProvider = context.watch<SensorProvider>();
    final roomsProvider = context.watch<RoomsProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ────────────────────────────────
              _buildHeader(context, sensorProvider, roomsProvider),

              // ─── Status bar ────────────────────────────
              _buildStatusBar(sensorProvider, roomsProvider),

              // ─── Room grid ─────────────────────────────
              Expanded(
                child: _buildRoomGrid(context, sensorProvider, roomsProvider),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        ),
        icon: const Icon(Icons.tune),
        label: const Text('Setup'),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SensorProvider sensor,
    RoomsProvider rooms,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // App icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.lightOnGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb, color: Color(0xFF1A1A1A), size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Smart Light Monitor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                sensor.isMonitoring
                    ? 'Monitoring ${sensor.roomName}'
                    : 'Not monitoring',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Monitoring toggle
          GestureDetector(
            onTap: () {
              if (sensor.isMonitoring) {
                sensor.stopMonitoring();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetupScreen()),
                );
              }
            },
            child: _MonitoringBadge(isActive: sensor.isMonitoring),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(SensorProvider sensor, RoomsProvider rooms) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppTheme.glassCard,
        child: Row(
          children: [
            _StatusChip(
              icon: Icons.devices,
              label: '${rooms.rooms.length}',
              subtitle: 'Devices',
            ),
            const SizedBox(width: 20),
            _StatusChip(
              icon: Icons.lightbulb,
              label: '${rooms.activeRoomCount}',
              subtitle: 'Lights On',
              color: AppTheme.lightOn,
            ),
            const SizedBox(width: 20),
            _StatusChip(
              icon: Icons.wb_sunny_outlined,
              label: sensor.currentLux.toStringAsFixed(0),
              subtitle: 'Your Lux',
              color: sensor.isLightOn ? AppTheme.lightOn : AppTheme.lightOff,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomGrid(
    BuildContext context,
    SensorProvider sensor,
    RoomsProvider rooms,
  ) {
    if (rooms.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.lightOn),
      );
    }

    if (rooms.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(rooms.error!, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: rooms.refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (rooms.rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No devices monitoring yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set up this device to start monitoring',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: rooms.rooms.length,
        itemBuilder: (context, index) {
          final room = rooms.rooms[index];
          return RoomCard(
            room: room,
            isCurrentDevice: room.deviceId == sensor.deviceId,
            onNudge: () => _handleNudge(context, room, sensor),
          );
        },
      ),
    );
  }

  void _handleNudge(
    BuildContext context,
    RoomData targetRoom,
    SensorProvider sensor,
  ) {
    if (!sensor.isMonitoring) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must start monitoring first to send requests!'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Send request to ${targetRoom.roomName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb, color: AppTheme.lightOn),
                title: const Text('Request to Turn ON lights', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _sendCommand(context, targetRoom, 'TURN_ON', sensor);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: AppTheme.lightOff),
                title: const Text('Request to Turn OFF lights', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _sendCommand(context, targetRoom, 'TURN_OFF', sensor);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _sendCommand(
    BuildContext context,
    RoomData targetRoom,
    String action,
    SensorProvider sensor,
  ) async {
    final success = await context.read<RoomsProvider>().firebaseService.sendCommand(
      targetDeviceId: targetRoom.deviceId,
      command: action,
      senderRoomName: sensor.roomName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '💡 Request sent to ${targetRoom.roomName}!'
                : 'Could not send request. Check your connection.',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }
}

/// Green/grey badge indicating monitoring state.
class _MonitoringBadge extends StatelessWidget {
  final bool isActive;
  const _MonitoringBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withValues(alpha: 0.15)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.success.withValues(alpha: 0.4)
              : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.success : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'LIVE' : 'OFF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isActive ? AppTheme.success : AppTheme.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small status chip for the info bar.
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
