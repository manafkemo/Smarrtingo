import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final Color color;

  const CustomButton({
    super.key,
    required this.onTap,
    required this.text,
    this.color = const Color(0xFF0F5257),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 300,
        height: 60,
        child: Stack(
          children: [
            // Main Shape
            Positioned.fill(
              child: CustomPaint(
                painter: ButtonShapePainter(color: color),
              ),
            ),
            // Inner Pill (lighter accent)
            Positioned(
              right: 8,
              top: 8,
              bottom: 8,
              width: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC8F3F0).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            // Text
            Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ButtonShapePainter extends CustomPainter {
  final Color color;

  ButtonShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Create the base pill shape
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final pillPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)));

    // 2. Create the "notch" or "bite" shape (a small circle)
    // Adjust position and radius to match the design reference
    final notchPath = Path()
      ..addOval(Rect.fromCircle(center: const Offset(20, 5), radius: 15));

    // 3. Subtract the notch from the pill
    final finalPath = Path.combine(PathOperation.difference, pillPath, notchPath);

    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
