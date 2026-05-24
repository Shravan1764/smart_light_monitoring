import 'package:flutter/material.dart';
import 'package:smart_light_monitoring/models/room_data.dart';
import 'package:smart_light_monitoring/theme/app_theme.dart';
import 'package:smart_light_monitoring/widgets/status_indicator.dart';

/// Premium glassmorphic card displaying a room's light status.
///
/// Shows room name, light on/off with animated bulb, lux value,
/// last updated time, and a nudge action button.
class RoomCard extends StatefulWidget {
  final RoomData room;
  final bool isCurrentDevice;
  final VoidCallback? onNudge;

  const RoomCard({
    super.key,
    required this.room,
    this.isCurrentDevice = false,
    this.onNudge,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.room.isLightOn) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RoomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.room.isLightOn != oldWidget.room.isLightOn) {
      if (widget.room.isLightOn) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOn = widget.room.isLightOn;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isOn
                  ? AppTheme.lightOn.withValues(alpha: 0.3 * _glowAnimation.value)
                  : AppTheme.border.withValues(alpha: 0.5),
              width: isOn ? 1.5 : 1.0,
            ),
            boxShadow: isOn
                ? AppTheme.lightOnShadow(_glowAnimation.value * 0.5)
                : AppTheme.cardShadow,
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: room name + status indicator
            Row(
              children: [
                StatusIndicator(isOn: isOn, size: 10),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.room.roomName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isCurrentDevice)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YOU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Bulb icon + status
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOn
                      ? AppTheme.lightOnGlow
                      : AppTheme.lightOffGlow.withValues(alpha: 0.1),
                ),
                child: Icon(
                  isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 32,
                  color: isOn ? AppTheme.lightOn : AppTheme.textMuted,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Lux value
            Center(
              child: Text(
                '${widget.room.luxValue.toStringAsFixed(0)} lux',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isOn ? AppTheme.lightOn : AppTheme.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 2),

            // Light status text
            Center(
              child: Text(
                isOn ? 'Light is ON' : 'Light is OFF',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isOn ? AppTheme.lightOn.withValues(alpha: 0.8) : AppTheme.textMuted,
                ),
              ),
            ),

            const Spacer(),

            // Footer: last updated + nudge button
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.room.lastUpdatedRelative,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const Spacer(),
                if (widget.onNudge != null)
                  _NudgeButton(onTap: widget.onNudge!),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated nudge icon button with ripple effect.
class _NudgeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NudgeButton({required this.onTap});

  @override
  State<_NudgeButton> createState() => _NudgeButtonState();
}

class _NudgeButtonState extends State<_NudgeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _isPressed = true);
    _controller.forward().then((_) {
      _controller.reverse();
      setState(() => _isPressed = false);
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isPressed
              ? AppTheme.accent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.notifications_active_outlined,
          size: 18,
          color: AppTheme.accent,
        ),
      ),
    );
  }
}
