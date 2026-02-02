import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class SmartStatsContent extends StatelessWidget {
  const SmartStatsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('AI Efficiency'),
          const SizedBox(height: 12),
          _buildPlaceholderStats(),
          const SizedBox(height: 24),
          
          _buildSectionTitle('Time Saved'),
          const SizedBox(height: 12),
          _buildTimeSavedPlaceholder(),
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

  Widget _buildPlaceholderStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Generated', '0', Icons.auto_awesome_outlined),
        _buildStatCard('Completed', '0', Icons.check_circle_outline),
        _buildStatCard('Efficiency', '0%', Icons.bolt_rounded),
        _buildStatCard('Adaptability', 'High', Icons.psychology_outlined),
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

  Widget _buildTimeSavedPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text('You have saved approximately', style: TextStyle(color: Colors.grey)),
          const Text('0 Minutes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const Text('by using Smart Tasks.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
