import 'package:flutter/material.dart';
import '../widgets/productivity_stats_view.dart';
import '../widgets/stats/habit_stats_content.dart';
import '../widgets/stats/timer_stats_content.dart';
import '../widgets/stats/smart_stats_content.dart';
import '../widgets/stats/calendar_stats_content.dart';
import '../utils/theme.dart';

class DashboardScreen extends StatelessWidget {
  final int initialTab;
  const DashboardScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    String title;
    Widget body;

    switch (initialTab) {
      case 0:
        title = 'Tasks Insights';
        body = const ProductivityStatsView();
        break;
      case 1:
        title = 'Calendar Load';
        body = const CalendarStatsContent();
        break;
      case 2:
        title = 'AI Efficiency';
        body = const SmartStatsContent();
        break;
      case 3:
        title = 'Habit Streaks';
        body = const HabitStatsContent();
        break;
      case 4:
        title = 'Focus Stats';
        body = const TimerStatsContent();
        break;
      default:
        title = 'Productivity Insights';
        body = const ProductivityStatsView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }
}
