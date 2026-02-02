import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/deepseek_service.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../widgets/break_down_dialog.dart';
import '../utils/theme.dart';


class SmartTodoScreen extends StatefulWidget {
  const SmartTodoScreen({super.key});

  @override
  State<SmartTodoScreen> createState() => _SmartTodoScreenState();
}

class _SmartTodoScreenState extends State<SmartTodoScreen> {
  List<Task> _generatedTasks = [];
  bool _isLoading = false;

  void _showBreakDownDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BreakDownDialog(
        onBreakDown: (goal) {
          _generateTasks(goal);
        },
      ),
    );
  }

  void _generateTasks(String goal) async {
    if (goal.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedTasks = [];
    });

    final deepSeekService = Provider.of<DeepSeekService>(context, listen: false);
    final tasks = await deepSeekService.generateSmartTasks(goal);

    if (mounted) {
      setState(() {
        _generatedTasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _addAllTasks() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    for (var task in _generatedTasks) {
      taskProvider.addTask(task);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_generatedTasks.length} tasks added to your list!')),
    );
    
    setState(() {
      _generatedTasks = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_generatedTasks.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Suggested Tasks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _addAllTasks,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Add All'),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _generatedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _generatedTasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: task.priority.color.withValues(alpha: 0.2),
                          child: Icon(Icons.circle, color: task.priority.color, size: 12),
                        ),
                        title: Text(task.title),
                        subtitle: Text(task.description),
                        trailing: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            Provider.of<TaskProvider>(context, listen: false).addTask(task);
                            setState(() {
                              _generatedTasks.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task added!')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Break Down Your Goals',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Use AI to transform your big ideas into actionable tasks',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _showBreakDownDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 22),
                          label: const Text(
                            'Break It Down',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
