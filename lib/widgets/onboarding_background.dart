import 'package:flutter/material.dart';

class OnboardingBackground extends StatelessWidget {
  const OnboardingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top Left Dark Circle
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFF0F5257),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Top Left Light Blob (overlapping)
        Positioned(
          top: 40,
          left: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFC8F3F0).withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
         // Bottom Left Light Blob
        Positioned(
          bottom: 40,
          left: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFC8F3F0).withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Bottom Right Dark Circle
        Positioned(
          bottom: -40,
          right: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFF0F5257),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Top Right Light Accent
        Positioned(
          top: 60,
          right: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFC8F3F0).withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
