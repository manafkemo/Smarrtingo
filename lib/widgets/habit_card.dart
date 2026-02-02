import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import 'habit_grid.dart'; // Now serving HabitHeatMap
import 'add_habit_dialog.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  bool _isYearlyView = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context);
    // final isCompletedToday = provider.isCompleted(widget.habit.id, DateTime.now()); // Unused
    final completionValue = provider.getCompletionValue(widget.habit.id, DateTime.now());
    final isFullyCompleted = completionValue >= widget.habit.dailyTarget;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(widget.habit.colorValue).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.habit.icon, color: Color(widget.habit.colorValue), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      if (widget.habit.category != null && widget.habit.category!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            widget.habit.category!,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_isYearlyView ? Icons.calendar_view_month : Icons.calendar_view_week, color: Colors.grey),
                  tooltip: _isYearlyView ? "Switch to Monthly View" : "Switch to Yearly View",
                  onPressed: () {
                    setState(() {
                      _isYearlyView = !_isYearlyView;
                    });
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'edit') {
                       showDialog(
                        context: context,
                        builder: (context) => AddHabitDialog(habitToEdit: widget.habit),
                      );
                    } else if (value == 'delete') {
                      provider.deleteHabit(widget.habit.id);
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
            const SizedBox(height: 20),
            
            // HeatMap
            Center(
              child: HabitHeatMap(
                habitId: widget.habit.id,
                baseColor: Color(widget.habit.colorValue),
                isYearlyView: _isYearlyView,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Interaction
            InkWell(
              onTap: isFullyCompleted ? null : () {
                 provider.incrementProgress(widget.habit.id, DateTime.now());
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isFullyCompleted 
                      ? Colors.grey[100] 
                      : Color(widget.habit.colorValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isFullyCompleted ? Colors.transparent : Color(widget.habit.colorValue),
                      width: 1
                  ),
                ),
                child: Center(
                  child: Text(
                    isFullyCompleted 
                        ? 'Completed for today' 
                        : (widget.habit.dailyTarget > 1 
                            ? 'Log Progress ($completionValue/${widget.habit.dailyTarget})' 
                            : 'Mark Complete'),
                    style: TextStyle(
                      color: isFullyCompleted ? Colors.grey : Color(widget.habit.colorValue),
                      fontWeight: FontWeight.w600,
                    ),
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
