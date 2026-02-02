import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_dialog.dart'; // For Edit
import 'habit_grid.dart';

class YearlyHabitRow extends StatelessWidget {
  final Habit habit;

  const YearlyHabitRow({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(habit.icon, color: Color(habit.colorValue), size: 24),
              const SizedBox(width: 12),
              Text(
                habit.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: Colors.grey[300]),
                  onSelected: (value) {
                    final provider = Provider.of<HabitProvider>(context, listen: false);
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
          const SizedBox(height: 12),
          HabitHeatMap(
            habitId: habit.id,
            baseColor: Color(habit.colorValue),
            isYearlyView: true,
          ),
        ],
      ),
    );
  }
}
