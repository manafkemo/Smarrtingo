import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_dialog.dart';
import 'habit_grid.dart'; // Reusing the updated HabitHeatMap

class MonthlyHabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;

  const MonthlyHabitCard({
    super.key,
    required this.habit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthFormat = DateFormat('MMM yyyy'); // e.g. "Dec 2025"
    
    // Check completion status for today
    final provider = Provider.of<HabitProvider>(context);
    final isCompletedToday = provider.isHabitCompletedToday(habit.id);

    
    final Color baseColor = Color(habit.colorValue);
    final Color tintColor = baseColor.withValues(alpha: 0.1);

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias, // Important for header background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
           // Tap anywhere to toggle today's completion (or increment)
           // If we follow the "max 5" rule, simple tap increments.
           // If we want a checkmark behavior: 
           // If not completed -> increment.
           // If completed (reached target) -> maybe nothing or show dialog?
           // Let's stick to incrementing progress.
           provider.incrementProgress(habit.id, DateTime.now());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Tint
            Container(
              padding: const EdgeInsets.all(12),
              color: tintColor,
              child: Row(
                children: [
                  // Icon / Checkmark Box
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompletedToday ? baseColor : Colors.white,
                      shape: BoxShape.circle,
                      border: isCompletedToday ? null : Border.all(color: baseColor.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        isCompletedToday ? habit.icon : Icons.check,
                        color: isCompletedToday ? Colors.white : baseColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                         Text(
                          monthFormat.format(now),
                          style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                 // Menu (hidden or small)
                 PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[600], size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (value) {
                      if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (context) => AddHabitDialog(habitToEdit: habit),
                          );
                      } else if (value == 'delete') {
                        provider.deleteHabit(habit.id);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Grid Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: HabitHeatMap(
                  habitId: habit.id,
                  baseColor: baseColor,
                  isYearlyView: false,
                  targetMonth: now,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
