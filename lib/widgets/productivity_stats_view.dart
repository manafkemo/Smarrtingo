import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class ProductivityStatsView extends StatelessWidget {
  const ProductivityStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);


    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('High-Level Summary'),
          const SizedBox(height: 12),
          _buildSummaryGrid(taskProvider),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Priority-Based Analysis'),
          const SizedBox(height: 12),
          _buildPriorityAnalysis(taskProvider),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Category-Based Analysis'),
          const SizedBox(height: 12),
          _buildCategoryAnalysis(taskProvider),
          const SizedBox(height: 24),
          
          _buildSectionTitle('7-Day Trend'),
          const SizedBox(height: 12),
          _buildTrendChart(taskProvider),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Actionable Insights'),
          const SizedBox(height: 12),
          _buildInsights(taskProvider),
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildSummaryGrid(TaskProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard('Total Tasks', provider.totalTasksCount.toString(), Icons.assignment_outlined),
        _buildSummaryCard('Completed', provider.completedTasksCount.toString(), Icons.check_circle_outline),
        _buildSummaryCard('Rate', '${provider.completionPercentage.toStringAsFixed(1)}%', Icons.percent),
        _buildSummaryCard('Streak', '${provider.currentStreak} Days', Icons.local_fire_department_outlined),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityAnalysis(TaskProvider provider) {
    final rates = provider.completionRateByPriority;
    final overdue = provider.overdueCountByPriority;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ...TaskPriority.values.reversed.map((priority) {
            final rate = rates[priority] ?? 0.0;
            final overdueCount = overdue[priority] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priority.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (overdueCount > 0)
                        Text(
                          '$overdueCount Overdue',
                          style: TextStyle(
                            color: priority == TaskPriority.high ? Colors.red : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: rate / 100,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: priority.color,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rate.toStringAsFixed(0)}% Completion',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis(TaskProvider provider) {
    final rates = provider.completionRateByCategory;
    if (rates.isEmpty) return const Text('No data available');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: rates.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(entry.key, style: const TextStyle(fontSize: 14)),
                ),
                Expanded(
                  flex: 7,
                  child: Row(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: entry.value / 100,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 35,
                        child: Text(
                          '${entry.value.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendChart(TaskProvider provider) {
    final trends = provider.getTasksCompletedLast7Days();
    final dates = trends.keys.toList().reversed.toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: dates.map((date) {
          final count = trends[date] ?? 0;
          final maxCount = trends.values.fold(1, (max, v) => v > max ? v : max);
          final barHeight = count == 0 ? 5.0 : (count / maxCount) * 100;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(count.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: barHeight,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: count > 0 ? 1.0 : 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('E').format(date).substring(0, 1),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsights(TaskProvider provider) {
    final insights = provider.getInsights();

    return Column(
      children: insights.map((insight) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4), // Light green success background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
