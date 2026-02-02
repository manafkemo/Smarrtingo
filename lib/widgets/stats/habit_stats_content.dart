import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit_model.dart';
import '../../utils/theme.dart';

class HabitStatsContent extends StatelessWidget {
  const HabitStatsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    if (habits.isEmpty) {
      return const Center(child: Text('No habits to analyze. Add some habits first!'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Overall Progress'),
          const SizedBox(height: 12),
          _buildOverallStats(habitProvider),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Top Streaks'),
          const SizedBox(height: 12),
          _buildStreaksList(habitProvider),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Category Breakdown'),
          const SizedBox(height: 12),
          _buildCategoryBreakdown(habitProvider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildOverallStats(HabitProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Habits', provider.habits.length.toString(), Icons.layers_outlined),
        _buildStatCard('Active Today', provider.habits.where((h) => provider.isHabitCompletedToday(h.id)).length.toString(), Icons.today_outlined),
        _buildStatCard('Avg Progress', '${_calculateAvgCompletions(provider)} Done', Icons.auto_graph_rounded),
        _buildStatCard('Categories', provider.categories.length.toString(), Icons.category_outlined),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStreaksList(HabitProvider provider) {
    // Calculate total completions per habit for ranking
    final habitsWithStats = provider.habits.map((habit) {
      final habitCompletions = provider.getCompletionsForHabit(habit.id);
      return {
        'habit': habit,
        'completions': habitCompletions.length,
      };
    }).toList();
    
    habitsWithStats.sort((a, b) => (b['completions'] as int).compareTo(a['completions'] as int));
    final topHabits = habitsWithStats.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: topHabits.map((item) {
          final habit = item['habit'] as Habit;
          final completions = item['completions'] as int;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: habit.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(habit.icon, color: habit.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('$completions total completions', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryBreakdown(HabitProvider provider) {
    final categoryCounts = <String, int>{};
    for (var habit in provider.habits) {
      final cat = habit.category ?? 'Uncategorized';
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: categoryCounts.entries.map((entry) {
          final percentage = (entry.value / provider.habits.length) * 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(entry.key, style: const TextStyle(fontSize: 14))),
                Expanded(
                  flex: 7,
                  child: Stack(
                    children: [
                      Container(height: 8, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
                      FractionallySizedBox(
                        widthFactor: percentage / 100,
                        child: Container(height: 8, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  int _calculateAvgCompletions(HabitProvider provider) {
    if (provider.habits.isEmpty) return 0;
    final totalCompletions = provider.habits.fold(0, (sum, h) => sum + provider.getCompletionsForHabit(h.id).length);
    return (totalCompletions / provider.habits.length).round();
  }
}
