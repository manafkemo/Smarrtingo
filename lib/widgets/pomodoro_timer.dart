import 'dart:math';
import 'package:flutter/material.dart';

class PomodoroTimer extends StatefulWidget {
  final Duration duration;
  final Duration totalDuration;
  final bool isSetupMode;
  final ValueChanged<Duration> onDurationChanged;
  final double size;

  const PomodoroTimer({
    super.key,
    required this.duration,
    required this.totalDuration,
    required this.isSetupMode,
    required this.onDurationChanged,
    this.size = 300,
  });

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  void _handlePanStart(DragStartDetails details) {
    if (!widget.isSetupMode) return;
    _handleInteraction(details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!widget.isSetupMode) return;
    _handleInteraction(details.localPosition);
  }

  void _handleInteraction(Offset localPosition) {
    if (!context.mounted) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset center = box.size.center(Offset.zero);
    final Offset touchOffset = localPosition - center;

    // Angle 0 is at 3 o'clock. We want 0 at 12 o'clock (-pi/2)
    final double angle = atan2(touchOffset.dy, touchOffset.dx);
    
    // Adjust so 0 is at 12 o'clock and it increases clockwise
    double adjustedAngle = angle + pi / 2;
    if (adjustedAngle < 0) adjustedAngle += 2 * pi;

    // Convert to minutes (0 to 60)
    int newMinutes = ((adjustedAngle / (2 * pi)) * 60).round();
    
    // Boundary protection for dragging
    int currentMinutes = widget.totalDuration.inMinutes;
    
    if (currentMinutes >= 58 && newMinutes <= 2) {
      newMinutes = 60;
    } else if (currentMinutes <= 2 && newMinutes >= 58) {
      newMinutes = 0;
    } else if (currentMinutes == 60 && newMinutes < 30) {
      newMinutes = 60;
    } else if (currentMinutes == 0 && newMinutes > 30) {
      newMinutes = 0;
    }

    newMinutes = newMinutes.clamp(0, 60);

    if (newMinutes != widget.totalDuration.inMinutes) {
      widget.onDurationChanged(Duration(minutes: newMinutes));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show remaining time status
    final displayDuration = widget.isSetupMode ? widget.totalDuration : widget.duration;
    // Calculate progress: 1.0 means full (60 mins or starting time).
    // The design shows a filled arc. 
    // Usually for countdown: start full, reduce to empty.
    // Or start empty, fill to full?
    // Let's assume standard countdown: Full circle = 60 mins.
    // Progress based on minute 0-60.
    
    double progress = displayDuration.inSeconds / (60 * 60);
    
    // If not setup mode (running), we might want to show relative progress?
    // But usually these dials show absolute time on a 60-min face.
    // Let's stick to 60-min face for consistency with Rotary.

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PomodoroPainter(
                progress: progress,
                trackColor: const Color(0xFFC8F3F0), // Light Teal
                progressColor: const Color(0xFF2D767B), // Dark Teal
              ),
            ),
            
            // Central Text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${displayDuration.inMinutes}:${(displayDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F5257),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications, size: 16, color: const Color(0xFF0F5257).withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      "FOCUS",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F5257).withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PomodoroPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _PomodoroPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 50.0; // Thick stroke as per design
    
    final paintRadius = radius - strokeWidth / 2;

    // 1. Draw Track (Background Circle)
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, paintRadius, trackPaint);

    // 2. Draw Progress Arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Start from top (-pi/2)
      // Sweep angle: 2 * pi * progress
      final sweepAngle = 2 * pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: paintRadius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );

      // 3. Draw Handle (White Dot)
      // Position is at the end of the arc
      final endAngle = -pi / 2 + sweepAngle;
      final handleX = center.dx + paintRadius * cos(endAngle);
      final handleY = center.dy + paintRadius * sin(endAngle);

      final handlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
        
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(handleX, handleY), strokeWidth * 0.4, shadowPaint);
      canvas.drawCircle(Offset(handleX, handleY), strokeWidth * 0.35, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PomodoroPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.trackColor != trackColor ||
           oldDelegate.progressColor != progressColor;
  }
}
