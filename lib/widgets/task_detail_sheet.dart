import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/theme.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'task_options_sheet.dart';

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
  late List<FocusNode> _subtaskFocusNodes;
  late List<String> _mediaPaths;
  bool _isCompleted = false;
  bool _areSubtasksVisible = false;
  Timer? _debounceTimer;



  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedCategory = widget.task.category;
    _selectedPriority = widget.task.priority;
    _subtasks = List.from(widget.task.subtasks);
    _subtaskFocusNodes = List.generate(_subtasks.length, (index) {
      final node = FocusNode();
      node.addListener(() => _checkEmptySubtask(node));
      return node;
    });
    _mediaPaths = List.from(widget.task.mediaPaths);
    _isCompleted = widget.task.isCompleted;
    _areSubtasksVisible = widget.task.subtasks.isNotEmpty;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    for (var node in _subtaskFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _debounceUpdateTask() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _updateTask();
    });
  }

  void _updateTask() {
    // Save to provider (with filtering for storage only)
    final validSubtasks = _subtasks.where((s) => s.title.trim().isNotEmpty).toList();

    final updatedTask = widget.task.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      priority: _selectedPriority,
      subtasks: validSubtasks,
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

  void _checkEmptySubtask(FocusNode node) {
    if (!node.hasFocus) {
      final index = _subtaskFocusNodes.indexOf(node);
      if (index != -1 && _subtasks[index].title.trim().isEmpty) {
        _removeSubtask(index);
      }
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
      _subtaskFocusNodes[index].dispose();
      _subtaskFocusNodes.removeAt(index);
    });
    _updateTask();
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
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const TaskOptionsSheet(),
                    );
                  },
                  child: const Icon(Icons.more_vert_rounded, color: Color(0xFF8B9E9E)),
                ),
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
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F5257),
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
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
                fontSize: 14,
                color: Color(0xFF2C2C2C),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                filled: false,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Add notes or use Smarttingo AI to break this task down into smaller actionable steps...',
                hintStyle: TextStyle(color: Color(0xFF8B9E9E)),
              ),
              onChanged: (val) => _updateTask(),
            ),
            const SizedBox(height: 20),

            // Subtasks List
            if (_areSubtasksVisible) ...[
              ..._subtasks.asMap().entries.map((entry) {
                final index = entry.key;
                final subtask = entry.value;
                return Padding(
                  key: ValueKey(subtask.id), // Add Key for proper state management
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
                            borderRadius: BorderRadius.circular(6), // Rounded square
                            border: Border.all(
                              color: const Color(0xFFD1F2ED),
                              width: 2,
                            ),
                            color: subtask.isCompleted ? const Color(0xFFD1F2ED) : Colors.transparent,
                          ),
                          child: subtask.isCompleted
                              ? const Icon(Icons.check, size: 16, color: Color(0xFF0F5257))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: subtask.title,
                          focusNode: _subtaskFocusNodes[index],
                          style: TextStyle(
                            fontSize: 14,
                            color: subtask.isCompleted ? const Color(0xFFACB9B9) : const Color(0xFF0F5257),
                            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.only(bottom: 8, top: 0), // Adjust padding
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE8EDED), width: 1),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF0F5257), width: 1),
                            ),
                            border: UnderlineInputBorder(
                               borderSide: BorderSide(color: Color(0xFFE8EDED)),
                            ),
                          ),
                          onChanged: (val) {
                             _subtasks[index] = subtask.copyWith(title: val);
                             _debounceUpdateTask(); // Debounced save
                          },
                          onFieldSubmitted: (val) {
                            if (val.trim().isEmpty) {
                              _removeSubtask(index);
                            } else {
                              _updateTask(); // Immediate save on Enter
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // "Add Subtask" Button
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      final newNode = FocusNode();
                      newNode.addListener(() => _checkEmptySubtask(newNode));
                      _subtaskFocusNodes.add(newNode);
                      _subtasks.add(SubTask(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: '',
                        isCompleted: false,
                      ));
                      // Ensure subtasks are visible if one is added
                      _areSubtasksVisible = true;
                    });
                     // Move focus to the new node after build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_subtaskFocusNodes.isNotEmpty) {
                        _subtaskFocusNodes.last.requestFocus();
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6), // Rounded square for add button too
                          border: Border.all(
                            color: const Color(0xFFD1F2ED),
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.add, size: 16, color: Color(0xFF0F5257)),
                      ),
                      const SizedBox(width: 12),
                      Expanded( // Expand to allow full width underline if needed for "Add Step", though usually just text
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE8EDED), width: 1))
                          ),
                          padding: const EdgeInsets.only(bottom: 8),
                          child: const Text(
                            'Add Step',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8B9E9E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

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
                    setState(() {
                      _areSubtasksVisible = !_areSubtasksVisible;
                    });
                  },
                  icon: Icon(
                    Icons.list_rounded,
                    color: _areSubtasksVisible ? const Color(0xFF0F5257) : const Color(0xFF8DBFAF), 
                    size: 28
                  ),
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
              children: taskProvider.categories.map((cat) => InkWell(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                  _updateTask();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0F5257)),
                  ),
                  child: Text(
                    cat.name, 
                    style: const TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F5257),
                    )
                  ),
                ),
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
