import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_dialog.dart';
import 'habit_grid.dart';

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
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        onTap: () {
          provider.incrementProgress(habit.id, DateTime.now());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Tint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: tintColor,
              child: Row(
                children: [
                  // Icon / Checkmark Box
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompletedToday ? baseColor : Colors.white,
                      shape: BoxShape.circle,
                      border: isCompletedToday ? null : Border.all(color: baseColor.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        isCompletedToday ? habit.icon : Icons.check,
                        color: isCompletedToday ? Colors.white : baseColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title & Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          monthFormat.format(now),
                          style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  // Menu
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
            
            // Grid Content (HeatMap)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Center(
                  child: HabitHeatMap(
                    habitId: habit.id,
                    baseColor: baseColor,
                    isYearlyView: false,
                    targetMonth: now,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
