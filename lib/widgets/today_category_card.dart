import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TodayCategoryCard extends StatelessWidget {
  final int taskCount;
  final bool isSelected;
  final VoidCallback onTap;

  const TodayCategoryCard({
    super.key,
    required this.taskCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Full width
        height: 80, // Slightly taller for better layout
        // Actually, other cards are likely taller (vertical stack). 
        // Design shows this as a wide button-like card.
        // Let's match height to standard CategoryCard if intended for the same row, 
        // OR make it a standout header element?
        // Layout in HomeScreen: `SingleChildScrollView` (horizontal).
        // If we put this in the same Row, it must have compatible height/alignment.
        // Standard CategoryCard has vertical padding 12, icon 36, text, count. ~100px height.
        // Let's set height to match roughly or let it expand.
        // Design: "Today's Focus 0 Tasks ->" in a horizontal row.
        // Let's try to match the height of the standard cards for visual consistency, 
        // or if it's meant to be much shorter, we'll see.
        // Looking at the standard card: ~110px.
        // The mock shows a pill shape. Let's make it 80-100px high but horizontal contents.
        decoration: BoxDecoration(
          color: AppColors.primary, // Dark Teal
          borderRadius: BorderRadius.circular(20), // More rounded
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Left Icon (Calendar) with circle background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Middle Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "TODAY'S FOCUS",
                    style: TextStyle(
                      color: AppColors.secondary.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$taskCount Tasks",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Right Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
