import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

import 'package:intl/intl.dart';

class HabitHeatMap extends StatelessWidget {
  final String habitId;
  final Color baseColor;
  final bool isYearlyView;
  final DateTime? targetMonth; // For monthly view: specific month to show

  const HabitHeatMap({
    super.key,
    required this.habitId,
    required this.baseColor,
    this.isYearlyView = false,
    this.targetMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (isYearlyView) {
      return _buildYearlyGrid(context);
    }
    
    return _buildMonthlyCalendar(context);
  }

  Widget _buildMonthlyCalendar(BuildContext context) {
    // Current month or target month
    final now = DateTime.now();
    final monthToShow = targetMonth ?? DateTime(now.year, now.month);
    
    final int daysInMonth = DateUtils.getDaysInMonth(monthToShow.year, monthToShow.month);
    final int firstWeekday = DateTime(monthToShow.year, monthToShow.month, 1).weekday; // 1=Mon...7=Sun
    
    // We want a Grid with 7 columns (Mon..Sun or Sun..Sat?)
    // Standard varies. Let's assume Mon-Sun for now as consistent with DateTime.
    // However, typical calendars often use Sun-Sat in US.
    // Let's stick to Mon-Sun (ISO 8601) unless specified. User didn't specify, but international standard is safer.
    // Actually, let's make it standard Mon-Sun.
    
    // Calculate total slots needed: offset + days
    // offset = firstWeekday - 1 (e.g. if Mon(1), offset 0. If Tue(2), offset 1)
    final int offset = firstWeekday - 1;
    final int totalSlots = offset + daysInMonth;
    
    // Layout: Column with Weekday Headers + Grid
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Weekday headers (M T W T F S S)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) => 
            SizedBox(
              width: 20, // Approx cell width
              child: Text(
                day, 
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            )
          ).toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: totalSlots,
          itemBuilder: (context, index) {
            if (index < offset) {
              return const SizedBox(); // Empty slot before 1st of month
            }
            
            final int day = index - offset + 1;
            final date = DateTime(monthToShow.year, monthToShow.month, day);
            final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
            
            // Don't show future days in the grid at all? Or show as empty placeholders?
            // "Future dates are visible but inactive"
            
            return _buildCell(context, date, 20.0, isFuture, isMonthly: true);
          },
        ),
      ],
    );
  }

  Widget _buildYearlyGrid(BuildContext context) {
    // 52 Weeks, GitHub Style.
    // Scrollable horizontal.
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 52 weeks * 7 days = 364 days.
    // End date = today.
    // Start date must be carefully calculated to align weeks.
    // We want the LAST column to be the current week (ending on Saturday or Sunday?)
    // Let's align columns to start on Monday.
    
    // Current week's Monday:
    final currentWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    // Start of the grid (51 weeks ago)
    final gridStartDate = currentWeekMonday.subtract(const Duration(days: 51 * 7));
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Start at the end (today)
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Labels
          Row(
            children: [
               const SizedBox(width: 28), // Match day label width + spacing
               ...List.generate(52, (colIndex) {
                 final weekStart = gridStartDate.add(Duration(days: colIndex * 7));
                 // Show month label if week contains the 1st, or closely approximates start
                 // Simplified: Show if it's the first week of a month?
                 // Or simple logic: check if weekStart day is <= 7
                 String text = "";
                 if (weekStart.day <= 7) {
                    text = DateFormat('MMM').format(weekStart);
                 }
                 
                 // Avoid clutter: if we just showed one recently?
                 // Simple logic first.
                 
                 return Container(
                   width: 15.0, // Match column width (12 + 3 margin)
                   alignment: Alignment.centerLeft,
                   child: text.isNotEmpty 
                      ? Text(
                          text, 
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        )
                      : null,
                 );
               }),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
           // Day Labels (Mon, Wed, Fri) - strictly 7 rows height aligned
           Column(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _buildDayLabel(''), // Mon -> Empty
               _buildDayLabel('Tue'),
               _buildDayLabel(''), // Wed -> Empty
               _buildDayLabel('Thu'), 
               _buildDayLabel(''), // Fri -> Empty
               _buildDayLabel('Sat'),
               _buildDayLabel(''), // Sun -> Empty
             ],
           ),
           const SizedBox(width: 4),
           
           // The Grid
           Row(
             children: List.generate(52, (colIndex) {
               final weekStart = gridStartDate.add(Duration(days: colIndex * 7));
               
               return Padding(
                 padding: const EdgeInsets.only(right: 3.0),
                 child: Column(
                   children: List.generate(7, (rowIndex) {
                     final date = weekStart.add(Duration(days: rowIndex));
                     final isFuture = date.isAfter(today);
                     return Container(
                       margin: const EdgeInsets.only(bottom: 3.0),
                       child: _buildCell(context, date, 12.0, isFuture),
                     );
                   }),
                 ),
               );
             }),
            ),
          ],
        ),
      ],
      ),
    );
  }
  
  Widget _buildDayLabel(String text) {
    return SizedBox(
      height: 12 + 3, // cell size + margin
      width: 28, // Fixed width to match header spacing
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ),
    );
  }

  Widget _buildCell(BuildContext context, DateTime date, double size, bool isFuture, {bool isMonthly = false}) {
    final provider = Provider.of<HabitProvider>(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final opacity = isFuture ? 0.0 : provider.getOpacity(habitId, date);
    
    return Tooltip(
      message: isFuture ? "Future" : "${date.day}/${date.month}: ${(opacity * 100).toInt()}%",
      child: InkWell(
         onTap: (isToday && !isFuture) ? () {
           provider.incrementProgress(habitId, date);
         } : null,
         borderRadius: BorderRadius.circular(2),
         child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFuture 
                ? Colors.grey[100] 
                : (opacity > 0 
                    ? baseColor.withValues(alpha: opacity) 
                    : baseColor.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(isMonthly ? 4 : 2),
            border: isToday 
                ? Border.all(color: Colors.black, width: 1.5) // Distinct border for today
                : null, 
          ),
        ),
      ),
    );
  }
}


