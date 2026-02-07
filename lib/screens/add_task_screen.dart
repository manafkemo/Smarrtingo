import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

import 'add_category_screen.dart';
import '../widgets/repeat_task_dialog.dart';

import '../widgets/ai_smart_dialog.dart';


class AddTaskScreen extends StatefulWidget {
  final Task? taskToEdit;
  const AddTaskScreen({super.key, this.taskToEdit});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  TaskPriority _selectedPriority = TaskPriority.none;
  TaskCategory _selectedCategory = TaskCategory.personal;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay? _selectedEndTime;
  bool _smartReminderEnabled = true;
  RepeatConfig? _repeatConfig;
  final List<String> _attachedMediaPaths = [];
  
  // Refactored Subtasks
  List<SubTask> _subtasks = []; 
  List<FocusNode> _subtaskFocusNodes = [];

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _selectedPriority = task.priority;
      _selectedCategory = task.category;
      _selectedDate = task.date;
      _selectedTime = TimeOfDay(hour: task.date.hour, minute: task.date.minute);
      if (task.endTime != null) {
        _selectedEndTime = TimeOfDay(hour: task.endTime!.hour, minute: task.endTime!.minute);
      }
      _repeatConfig = task.repeatConfig;
      
      _attachedMediaPaths.addAll(task.mediaPaths);
      
      // Initialize subtasks and focus nodes
      _subtasks = List.from(task.subtasks);
      _subtaskFocusNodes = List.generate(_subtasks.length, (index) {
          final node = FocusNode();
          node.addListener(() => _checkEmptySubtask(node));
          return node;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var node in _subtaskFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _checkEmptySubtask(FocusNode node) {
    if (!node.hasFocus) {
      final index = _subtaskFocusNodes.indexOf(node);
      if (index != -1 && index < _subtasks.length && _subtasks[index].title.trim().isEmpty) {
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
  }
  
  void _addSubtask() {
    setState(() {
      final newNode = FocusNode();
      newNode.addListener(() => _checkEmptySubtask(newNode));
      _subtaskFocusNodes.add(newNode);
      _subtasks.add(SubTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        isCompleted: false,
      ));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_subtaskFocusNodes.isNotEmpty) {
        _subtaskFocusNodes.last.requestFocus();
      }
    });
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final DateTime finalDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      DateTime? finalEndTime;
      if (_selectedEndTime != null) {
        finalEndTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedEndTime!.hour,
          _selectedEndTime!.minute,
        );
      }

      final validSubtasks = _subtasks.where((s) => s.title.trim().isNotEmpty).toList();

      final newTask = Task(
        id: _isEditing ? widget.taskToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        category: _selectedCategory,
        date: finalDateTime,
        endTime: finalEndTime,
        isCompleted: _isEditing ? widget.taskToEdit!.isCompleted : false,
        repeatConfig: _repeatConfig,
        subtasks: List.from(validSubtasks),
        mediaPaths: List.from(_attachedMediaPaths),
      );

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (_isEditing) {
        taskProvider.updateTask(newTask);
      } else {
        taskProvider.addTask(newTask);
      }
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay(hour: _selectedTime.hour + 1, minute: _selectedTime.minute),
    );
    if (picked != null) setState(() => _selectedEndTime = picked);
  }

  Future<void> _pickAttachments() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0F5257)),
              title: const Text('Pick Images'),
              onTap: () async {
                Navigator.pop(context);
                final ImagePicker picker = ImagePicker();
                final List<XFile> images = await picker.pickMultiImage();
                if (images.isNotEmpty) {
                  setState(() {
                    _attachedMediaPaths.addAll(images.map((e) => e.path));
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Color(0xFF0F5257)),
              title: const Text('Pick Files'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.any,
                );
                if (result != null && result.files.isNotEmpty) {
                  setState(() {
                    _attachedMediaPaths.addAll(result.files.map((e) => e.path!));
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Thick top border
          Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFF0F5257),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing ? 'Edit Task' : 'Add New Task',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF081C21),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Define your next small win',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF8B9E9E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1FDFB),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.close, color: Color(0xFF0F5257), size: 24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Title Input
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 18, color: Color(0xFF08191C)),
                        decoration: InputDecoration(
                          hintText: 'Title',
                          hintStyle: const TextStyle(color: Color(0xFFACB9B9), fontSize: 18),
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFFD9F4F0), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: Color(0xFF0F5257), width: 1.5),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 18),

                      // Description Input with Subtasks
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Description text input
                          TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 16, color: Color(0xFF08191C)),
                            decoration: const InputDecoration(
                              hintText: 'Add description...',
                              hintStyle: TextStyle(color: Color(0xFFACB9B9), fontSize: 16),
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.fromLTRB(0, 12, 0, 12),
                            ),
                          ),
                          
                          // Subtasks list with inline editing
                          if (_subtasks.isNotEmpty)
                            Column(
                              children: _subtasks.asMap().entries.map((entry) {
                                final index = entry.key;
                                final subtask = entry.value;

                                String placeholder;
                                if (index == 0) {
                                  placeholder = 'First sub-task step';
                                } else if (index == 1) {
                                  placeholder = 'Second sub-task step';
                                } else {
                                  placeholder = 'Add more sub-tasks...';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      // Square hollow checkbox
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: const Color(0xFF90C1B9),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: subtask.title,
                                          focusNode: _subtaskFocusNodes[index],
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: subtask.isCompleted ? const Color(0xFFACB9B9) : const Color(0xFF536969),
                                            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: placeholder,
                                            hintStyle: const TextStyle(color: Color(0xFFD1E0E0)),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.only(bottom: 8),
                                            border: const UnderlineInputBorder(
                                              borderSide: BorderSide(color: Color(0xFFE8EDED)),
                                            ),
                                            enabledBorder: const UnderlineInputBorder(
                                              borderSide: BorderSide(color: Color(0xFFE8EDED)),
                                            ),
                                            focusedBorder: const UnderlineInputBorder(
                                              borderSide: BorderSide(color: Color(0xFF0F5257)),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            _subtasks[index] = subtask.copyWith(title: val);
                                          },
                                          onFieldSubmitted: (val) {
                                            if (val.trim().isEmpty) {
                                              _removeSubtask(index);
                                            } else {
                                               _addSubtask();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          
                          // "Add Step" button
                          if (_subtasks.isNotEmpty) 
                           GestureDetector(
                              onTap: _addSubtask,
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF90C1B9),
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: Color(0xFF90C1B9),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                   Expanded(
                                     child: Container(
                                       decoration: const BoxDecoration(
                                         border: Border(bottom: BorderSide(color: Color(0xFFE8EDED), width: 1))
                                       ),
                                       padding: const EdgeInsets.only(bottom: 8),
                                       child: const Text(
                                         'Add Step',
                                         style: TextStyle(
                                           fontSize: 16,
                                           color: Color(0xFF8B9E9E),
                                         ),
                                       ),
                                     ),
                                   ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      // Attachment Preview
                      if (_attachedMediaPaths.isNotEmpty)
                        const SizedBox(height: 12),
                      if (_attachedMediaPaths.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _attachedMediaPaths.length,
                            itemBuilder: (context, index) {
                              final path = _attachedMediaPaths[index];
                              final isImage = path.toLowerCase().endsWith('.jpg') ||
                                  path.toLowerCase().endsWith('.jpeg') ||
                                  path.toLowerCase().endsWith('.png') ||
                                  path.toLowerCase().endsWith('.gif');
                              
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FCFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD9F4F0),
                                    width: 1.5,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: isImage
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: kIsWeb 
                                                ? Image.network(
                                                    path,
                                                    fit: BoxFit.cover,
                                                    width: 80,
                                                    height: 80,
                                                  )
                                                : Image.file(
                                                    File(path),
                                                    fit: BoxFit.cover,
                                                    width: 80,
                                                    height: 80,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.insert_drive_file,
                                              color: Color(0xFF0F5257),
                                              size: 32,
                                            ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _attachedMediaPaths.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Horizontal Action Buttons
                      Row(
                        children: [
                          _buildQuickActionButton(
                            Icons.list_alt_rounded,
                            isSelected: _subtasks.isNotEmpty,
                            onTap: () {
                              if (_subtasks.isEmpty) {
                                _addSubtask();
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildQuickActionButton(
                            Icons.attach_file_rounded,
                            onTap: _pickAttachments,
                          ),
                          const SizedBox(width: 12),
                          _buildQuickActionButton(
                            Icons.sync_rounded,
                            isSelected: _repeatConfig != null,
                            onTap: () async {
                               final config = await showDialog<RepeatConfig>(
                                  context: context,
                                  builder: (context) => RepeatTaskDialog(initialConfig: _repeatConfig),
                                );
                                if (config != null) {
                                  setState(() => _repeatConfig = config);
                                }
                            },
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 24,
                            width: 1.5,
                            color: const Color(0xFFE8EDED),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                              final result = await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (context) => AISmartDialog(
                                  initialTaskState: {
                                    'title': _titleController.text,
                                    'description': _descriptionController.text,
                                    'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                                    'time': '${_selectedTime.hour}:${_selectedTime.minute}',
                                    'category_id': _selectedCategory.id,
                                    'priority': _selectedPriority.toString().split('.').last,
                                    'subtasks': _subtasks.map((e) => e.title).toList(),
                                  },
                                ),
                              );
                              
                              if (result != null && result.isNotEmpty) {
                                setState(() {
                                  if (result.containsKey('title')) {
                                    _titleController.text = result['title'];
                                  }
                                  if (result.containsKey('description')) {
                                    _descriptionController.text = result['description'];
                                  }
                                  if (result.containsKey('date')) {
                                    try {
                                      _selectedDate = DateTime.parse(result['date']);
                                    } catch (e) {
                                      debugPrint('Error parsing date: $e');
                                    }
                                  }
                                  if (result.containsKey('time')) {
                                    try {
                                      final parts = (result['time'] as String).split(':');
                                      if (parts.length == 2) {
                                        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
                                      }
                                    } catch (e) {
                                      debugPrint('Error parsing time: $e');
                                    }
                                  }
                                  if (result.containsKey('priority')) {
                                    final priorityStr = (result['priority'] as String).toLowerCase();
                                    _selectedPriority = TaskPriority.values.firstWhere(
                                      (e) => e.toString().split('.').last == priorityStr,
                                      orElse: () => _selectedPriority,
                                    );
                                  }
                                  if (result.containsKey('category_id')) {
                                    final catId = result['category_id'];
                                    try {
                                      _selectedCategory = taskProvider.categories.firstWhere((c) => c.id == catId);
                                    } catch (e) {
                                      debugPrint('Category not found: $catId');
                                    }
                                  }
                                  if (result.containsKey('subtasks')) {
                                    final List<dynamic> subs = result['subtasks'];
                                    _subtasks.clear();
                                    for (var node in _subtaskFocusNodes) node.dispose();
                                    
                                    _subtasks.addAll(subs.map((t) => SubTask(
                                      id: DateTime.now().add(Duration(milliseconds: subs.indexOf(t))).millisecondsSinceEpoch.toString(),
                                      title: t.toString(),
                                      isCompleted: false,
                                    )));
                                    
                                    _subtaskFocusNodes = List.generate(_subtasks.length, (index) {
                                        final node = FocusNode();
                                        node.addListener(() => _checkEmptySubtask(node));
                                        return node;
                                    });

                                    if (_subtasks.isNotEmpty) {
                                      // Logic update: Ensure UI shows subtasks
                                    }
                                  }
                                });
                              }
                            },
                            child: const Row(
                              children: [
                                 Icon(Icons.auto_awesome, size: 22, color: Color(0xFF0F5257)),
                                SizedBox(width: 8),
                                Text(
                                  'Smarttingo',
                                  style: TextStyle(
                                    color: Color(0xFF0F5257),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Date & Time
                      const Text(
                        'Date',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF08191C)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoButton(
                              icon: Icons.calendar_today_rounded,
                              label: _isToday(_selectedDate) ? 'Today' : DateFormat('MMM d, y').format(_selectedDate),
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoButton(
                              icon: Icons.access_time_filled,
                              label: _selectedTime.format(context),
                              onTap: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Deadline
                      Row(
                        children: [
                          const Text(
                            'Deadline',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF08191C)),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '(Optional)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFACB9B9)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildInfoButton(
                        icon: Icons.notifications_off_rounded,
                        label: _selectedEndTime != null ? 'Until ${_selectedEndTime!.format(context)}' : 'None',
                        onTap: _pickEndTime,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 28),

                      // Priority
                      const Text(
                        'Priority',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF08191C)),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildModernPriorityChip(TaskPriority.none, 'None'),
                          const SizedBox(width: 10),
                          _buildModernPriorityChip(TaskPriority.low, 'Low'),
                          const SizedBox(width: 10),
                          _buildModernPriorityChip(TaskPriority.medium, 'Medium'),
                          const SizedBox(width: 10),
                          _buildModernPriorityChip(TaskPriority.high, 'High'),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Category
                      Row(
                        children: [
                          const Text(
                             'Category',
                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF08191C)),
                          ),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: _showCategoryPicker,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF1FF), // Soft lavender blue
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_selectedCategory.icon, size: 18, color: const Color(0xFF6E78FF)),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedCategory.name,
                                    style: const TextStyle(color: Color(0xFF6E78FF), fontWeight: FontWeight.w800, fontSize: 13),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF6E78FF)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Smart Reminder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Smart reminder',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF08191C)),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: _smartReminderEnabled,
                              onChanged: (val) => setState(() => _smartReminderEnabled = val),
                              activeThumbColor: const Color(0xFF0F5257),
                              activeTrackColor: const Color(0xFFD1F2ED),
                              inactiveTrackColor: const Color(0xFFE8EDED),
                              inactiveThumbColor: Colors.white,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Create Task Button
                      Container(
                        width: double.infinity,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F5257).withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saveTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D4D4D), // Deeper dark teal
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: Text(
                            _isEditing ? 'Update Task' : 'Create Task',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Cancel Button
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel', 
                            style: TextStyle(
                              color: Color(0xFF8B9E9E), 
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, {required VoidCallback onTap, bool isSelected = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F5257) : const Color(0xFFD9F4F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF0F5257), size: 24),
      ),
    );
  }

  Widget _buildInfoButton({required IconData icon, required String label, required VoidCallback onTap, bool fullWidth = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9F4F0), width: 1.5),
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: const Color(0xFF0F5257)),
            const SizedBox(width: 14),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: const TextStyle(color: Color(0xFF08191C), fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPriorityChip(TaskPriority priority, String label) {
    final isSelected = _selectedPriority == priority;
    Color color;
    Color bgColor;
    switch (priority) {
      case TaskPriority.none: 
        color = const Color(0xFF536969); 
        bgColor = const Color(0xFFF1F3F3);
        break;
      case TaskPriority.low: 
        color = const Color(0xFF2EBD59); 
        bgColor = const Color(0xFFF1FBF4);
        break;
      case TaskPriority.medium: 
        color = const Color(0xFFF39626); 
        bgColor = const Color(0xFFFEF6ED);
        break;
      case TaskPriority.high: 
        color = const Color(0xFFF85D5D); 
        bgColor = const Color(0xFFFFF1F1);
        break;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = priority),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : const Color(0xFFF1FDFB),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.3) : const Color(0xFFD9F4F0), 
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (priority != TaskPriority.none) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF08191C) : const Color(0xFFACB9B9),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showCategoryPicker() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final categories = taskProvider.categories;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDED),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Select Category', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF081C21))),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: categories.map((cat) => _buildCategorySelectionChip(cat)).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCategoryScreen()));
                    setState(() {});
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF0F5257)),
                  label: const Text('New Category', style: TextStyle(color: Color(0xFF0F5257), fontWeight: FontWeight.w800, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD9F4F0), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelectionChip(TaskCategory category) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 20, color: category.color),
            const SizedBox(width: 10),
            Text(category.name, style: TextStyle(color: category.color, fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}


