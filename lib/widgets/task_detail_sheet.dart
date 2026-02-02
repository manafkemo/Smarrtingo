import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/theme.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class TaskDetailSheet extends StatefulWidget {
  final Task task;

  const TaskDetailSheet({super.key, required this.task});

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskCategory _selectedCategory;
  late TaskPriority _selectedPriority;
  late List<SubTask> _subtasks;
  late List<String> _mediaPaths;
  bool _isCompleted = false;
  final TextEditingController _newSubtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedCategory = widget.task.category;
    _selectedPriority = widget.task.priority;
    _subtasks = List.from(widget.task.subtasks);
    _mediaPaths = List.from(widget.task.mediaPaths);
    _isCompleted = widget.task.isCompleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _updateTask() {
    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      priority: _selectedPriority,
      subtasks: _subtasks,
      mediaPaths: _mediaPaths,
      isCompleted: _isCompleted,
    );
    Provider.of<TaskProvider>(context, listen: false).updateTask(updatedTask);
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _mediaPaths.add(image.path);
      });
      _updateTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle/Indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDED),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Category, Priority Flag, More
            Row(
              children: [
                _buildCategorySelector(),
                const Spacer(),
                _buildPriorityFlag(),
                const SizedBox(width: 20),
                const Icon(Icons.more_vert_rounded, color: Color(0xFF8B9E9E)),
              ],
            ),
            const SizedBox(height: 24),

            // Date and Reminder Row
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD9F4F0), width: 1.5),
                  ),
                  child: Checkbox(
                    value: _isCompleted,
                    onChanged: (val) {
                      setState(() => _isCompleted = val ?? false);
                      _updateTask();
                    },
                    activeColor: AppColors.primary,
                    side: BorderSide.none,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Date and Reminder',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF8B9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F5257),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Task Name',
              ),
              onChanged: (val) => _updateTask(),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: null,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Add notes or use Smarttingo AI to break this task down into smaller actionable steps...',
                hintStyle: TextStyle(color: Color(0xFF8B9E9E)),
              ),
              onChanged: (val) => _updateTask(),
            ),
            const SizedBox(height: 20),

            // Subtasks List
            ..._subtasks.asMap().entries.map((entry) {
              final index = entry.key;
              final subtask = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _subtasks[index] = subtask.copyWith(isCompleted: !subtask.isCompleted);
                        });
                        _updateTask();
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD1F2ED),
                            width: 2,
                          ),
                          color: subtask.isCompleted ? const Color(0xFFD1F2ED) : Colors.transparent,
                        ),
                        child: subtask.isCompleted
                            ? const Icon(Icons.check, size: 14, color: Color(0xFF0F5257))
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: TextStyle(
                          fontSize: 15,
                          color: subtask.isCompleted ? const Color(0xFFACB9B9) : const Color(0xFF536969),
                          decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Add more subtasks field
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD1F2ED),
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _newSubtaskController,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF536969)),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'First sub-task step', // Match user image content placeholder
                        hintStyle: TextStyle(color: Color(0xFFD9F4F0)),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _subtasks.add(SubTask(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: val.trim(),
                              isCompleted: false,
                            ));
                            _newSubtaskController.clear();
                          });
                          _updateTask();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Photos Section (Only visible if photos exist, per user request)
            if (_mediaPaths.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 20),
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1FDFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD9F4F0),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _mediaPaths.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_mediaPaths[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _mediaPaths.removeAt(index);
                                });
                                _updateTask();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

            // Bottom Bar: Subtasks, Attachments
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // Logic to focus the 'Add more sub-tasks' field or similar
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(Icons.list_rounded, color: Color(0xFF8DBFAF), size: 28),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _pickMedia, // Implement media picking here
                  icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF8DBFAF), size: 28),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return InkWell(
      onTap: _showCategoryPicker,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1FDFB),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedCategory.name,
              style: const TextStyle(
                color: Color(0xFF0F5257),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF0F5257)),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: taskProvider.categories.map((cat) => ActionChip(
                label: Text(cat.name),
                onPressed: () {
                  setState(() => _selectedCategory = cat);
                  _updateTask();
                  Navigator.pop(context);
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityFlag() {
    Color flagColor;
    switch (_selectedPriority) {
      case TaskPriority.none:
        flagColor = Colors.grey;
        break;
      case TaskPriority.low:
        flagColor = Colors.green;
        break;
      case TaskPriority.medium:
        flagColor = Colors.orange;
        break;
      case TaskPriority.high:
        flagColor = Colors.red;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          // Cycle through priorities
          final values = TaskPriority.values;
          _selectedPriority = values[(_selectedPriority.index + 1) % values.length];
        });
        _updateTask();
      },
      child: Icon(Icons.flag_rounded, color: flagColor, size: 28),
    );
  }
}
