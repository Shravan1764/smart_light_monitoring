import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_light_monitoring/providers/sensor_provider.dart';
import 'package:smart_light_monitoring/theme/app_theme.dart';
import 'package:smart_light_monitoring/widgets/lux_gauge.dart';

/// Setup screen for configuring room name and calibrating the light threshold.
///
/// Shows a live lux gauge, room name field, calibration controls,
/// and a manual threshold slider.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _roomNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<SensorProvider>();
    _roomNameController.text = provider.roomName;

    // Start sensor listening for live preview
    provider.startSensorListening();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SensorProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Back + Title ────────────────────────
                _buildAppBar(context),
                const SizedBox(height: 32),

                // ─── Live Lux Gauge ──────────────────────
                _buildLuxSection(provider),
                const SizedBox(height: 32),

                // ─── Room Name ───────────────────────────
                _buildRoomNameSection(provider),
                const SizedBox(height: 24),

                // ─── Calibration ─────────────────────────
                _buildCalibrationSection(provider),
                const SizedBox(height: 24),

                // ─── Manual Threshold ────────────────────
                _buildThresholdSlider(provider),
                const SizedBox(height: 32),

                // ─── Start/Stop Monitoring ───────────────
                _buildMonitoringButton(provider),
                const SizedBox(height: 16),

                if (provider.isMonitoring) _buildStopButton(provider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room Setup',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              'Configure your light monitor',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLuxSection(SensorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassCard,
      child: Column(
        children: [
          const Text(
            'AMBIENT LIGHT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          LuxGauge(
            currentLux: provider.currentLux,
            maxLux: 1000,
            size: 200,
          ),
          const SizedBox(height: 16),
          Text(
            provider.isLightOn ? '💡 Light detected' : '🌙 Dark environment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: provider.isLightOn ? AppTheme.lightOn : AppTheme.lightOff,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomNameSection(SensorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.room, size: 18, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'Room Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomNameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Bedroom, Living Room',
            ),
            onChanged: (value) => provider.setRoomName(value.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationSection(SensorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18, color: AppTheme.lightOn),
              const SizedBox(width: 8),
              const Text(
                'Calibration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (provider.isCalibrated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CALIBRATED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.success,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to capture the current ambient light '
            'as your threshold. Values above this will be treated as "light on".',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final threshold = await provider.calibrate();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Threshold set to ${threshold.toStringAsFixed(1)} lux',
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Calibrate Now'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Current threshold: ${provider.thresholdLux.toStringAsFixed(1)} lux',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider(SensorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.linear_scale, size: 18, color: AppTheme.lightOff),
              SizedBox(width: 8),
              Text(
                'Manual Threshold',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('0', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.lightOn,
                    inactiveTrackColor: AppTheme.border,
                    thumbColor: AppTheme.lightOn,
                    overlayColor: AppTheme.lightOn.withValues(alpha: 0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: provider.thresholdLux.clamp(0, 1000),
                    min: 0,
                    max: 1000,
                    divisions: 100,
                    onChanged: (value) => provider.setThreshold(value),
                  ),
                ),
              ),
              const Text('1000', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          Center(
            child: Text(
              '${provider.thresholdLux.toStringAsFixed(0)} lux',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.lightOn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringButton(SensorProvider provider) {
    final canStart = provider.roomName.isNotEmpty && provider.isCalibrated;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: canStart && !provider.isMonitoring
              ? () async {
                  final started = await provider.startMonitoring();
                  if (!started) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to start background monitoring'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                    return;
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🟢 Monitoring started!'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              : null,
          icon: Icon(
            provider.isMonitoring ? Icons.check_circle : Icons.play_arrow,
          ),
          label: Text(
            provider.isMonitoring
                ? 'Already Monitoring'
                : canStart
                    ? 'Start Monitoring'
                    : 'Set room name & calibrate first',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: provider.isMonitoring
                ? AppTheme.success.withValues(alpha: 0.2)
                : null,
            disabledBackgroundColor: AppTheme.surface,
            disabledForegroundColor: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildStopButton(SensorProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () async {
          await provider.stopMonitoring();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🔴 Monitoring stopped'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        },
        icon: const Icon(Icons.stop, color: AppTheme.error),
        label: const Text('Stop Monitoring', style: TextStyle(color: AppTheme.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.error.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
