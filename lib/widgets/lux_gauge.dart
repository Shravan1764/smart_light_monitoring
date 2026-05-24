import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:smart_light_monitoring/theme/app_theme.dart';

/// Animated circular gauge displaying the current lux level.
///
/// Color transitions: dark blue (low) → amber (medium) → bright yellow (high).
class LuxGauge extends StatefulWidget {
  final double currentLux;
  final double maxLux;
  final double size;

  const LuxGauge({
    super.key,
    required this.currentLux,
    this.maxLux = 1000.0,
    this.size = 180.0,
  });

  @override
  State<LuxGauge> createState() => _LuxGaugeState();
}

class _LuxGaugeState extends State<LuxGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousLux = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.currentLux).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(LuxGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLux != widget.currentLux) {
      _previousLux = oldWidget.currentLux;
      _animation = Tween<double>(
        begin: _previousLux,
        end: widget.currentLux,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _luxColor(double lux) {
    final ratio = (lux / widget.maxLux).clamp(0.0, 1.0);
    if (ratio < 0.3) {
      return Color.lerp(AppTheme.lightOff, AppTheme.textSecondary, ratio / 0.3)!;
    } else if (ratio < 0.6) {
      return Color.lerp(AppTheme.textSecondary, AppTheme.lightOn, (ratio - 0.3) / 0.3)!;
    } else {
      return Color.lerp(AppTheme.lightOn, const Color(0xFFFFE066), (ratio - 0.6) / 0.4)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final lux = _animation.value;
        final color = _luxColor(lux);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background arc
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugeArcPainter(
                  progress: 1.0,
                  color: AppTheme.border.withValues(alpha: 0.3),
                  strokeWidth: 10,
                ),
              ),
              // Foreground arc (animated)
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugeArcPainter(
                  progress: (lux / widget.maxLux).clamp(0.0, 1.0),
                  color: color,
                  strokeWidth: 10,
                  hasShadow: true,
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lux.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: widget.size * 0.2,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LUX',
                    style: TextStyle(
                      fontSize: widget.size * 0.08,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugeArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasShadow;

  _GaugeArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.hasShadow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = 0.75 * math.pi;
    const totalSweep = 1.5 * math.pi;
    final sweepAngle = totalSweep * progress;

    if (hasShadow && progress > 0) {
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        shadowPaint,
      );
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GaugeArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
