import 'package:flutter/material.dart';
import 'package:smart_light_monitoring/theme/app_theme.dart';

/// Animated pulsing dot indicating light on/off status.
class StatusIndicator extends StatefulWidget {
  final bool isOn;
  final double size;

  const StatusIndicator({
    super.key,
    required this.isOn,
    this.size = 12.0,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isOn) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn != oldWidget.isOn) {
      widget.isOn ? _controller.repeat(reverse: true) : _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOn ? AppTheme.lightOn : AppTheme.textMuted;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: widget.isOn
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6 * _pulse.value),
                      blurRadius: 8 * _pulse.value,
                      spreadRadius: 2 * _pulse.value,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}
