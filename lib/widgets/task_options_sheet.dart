import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'share_task_sheet.dart';

class TaskOptionsSheet extends StatelessWidget {
  final Task task;

  const TaskOptionsSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
  
            // Options List
            _buildOptionItem(
              icon: Icons.chat_bubble_rounded,
              color: Colors.blueAccent,
              text: 'Comment',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDivider(),
            
            _buildOptionItem(
              icon: Icons.play_circle_fill_rounded,
              color: Colors.redAccent,
              text: 'Start Focus',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDivider(),
  
            _buildOptionItem(
              icon: Icons.push_pin_rounded,
              color: task.isPinned == true ? const Color(0xFF0F5257) : Colors.orange,
              text: task.isPinned == true ? 'Unpin' : 'Pin',
              onTap: () {
                Provider.of<TaskProvider>(context, listen: false).togglePinTask(task.id);
                Navigator.pop(context);
              },
            ),
            _buildDivider(),
  
            _buildOptionItem(
              icon: Icons.save_rounded,
              color: Colors.deepPurpleAccent,
              text: 'Save As Template',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDivider(),
  
            _buildOptionItem(
              icon: Icons.share_rounded,
              color: Colors.teal,
              text: 'Share',
              onTap: () {
                Navigator.pop(context); // Close Options sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ShareTaskSheet(task: task),
                );
              },
            ),
            _buildDivider(),
  
            _buildOptionItem(
              icon: Icons.archive_rounded,
              color: Colors.blueGrey,
              text: 'Archive',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDivider(),
  
            _buildOptionItem(
              icon: Icons.delete_rounded,
              color: Colors.redAccent,
              text: 'Delete Task', 
              textColor: Colors.redAccent,
              onTap: () {
                Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
                Navigator.pop(context); // Close Options sheet
                Navigator.pop(context); // Close Detail sheet
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1, 
      thickness: 1, 
      color: Color(0xFFF5F7F7),
      indent: 64, // Indent to align with text start
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
    Color textColor = const Color(0xFF3B4A4A), // Default dark grey text
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
