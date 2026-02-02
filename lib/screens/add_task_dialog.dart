import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

import 'add_category_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../widgets/ai_smart_dialog.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? taskToEdit;
  
  const AddTaskDialog({super.key, this.taskToEdit});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.none;
  TaskCategory _selectedCategory = TaskCategory.personal;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TimeOfDay? _selectedEndTime;


  // New fields
  List<String> _mediaPaths = [];
  List<SubTask> _subtasks = [];
  final _subtaskController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
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
      _mediaPaths = List.from(task.mediaPaths);
      _subtasks = List.from(task.subtasks);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
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
        if (finalEndTime.isBefore(finalDateTime)) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deadline cannot be before start time')),
             );
             return;
        }
      }

      // Check for Max 3 Tasks Overlap
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final existingTasks = taskProvider.tasks;
      final newTaskStart = finalDateTime;
      final newTaskEnd = finalEndTime ?? finalDateTime.add(const Duration(hours: 1));

      // Filter tasks relevant to the day and potential overlap
      final overlappingTasks = existingTasks.where((t) {
        if (t.isCompleted) return false; 
        if (t.date.year != newTaskStart.year || 
            t.date.month != newTaskStart.month || 
            t.date.day != newTaskStart.day) {
          return false;
        }
        
        final tStart = t.date;
        final tEnd = t.endTime ?? t.date.add(const Duration(hours: 1));

        return tStart.isBefore(newTaskEnd) && tEnd.isAfter(newTaskStart);
      }).toList();

      // Check concurrency
      int maxConcurrency = 0;
      List<DateTime> points = [newTaskStart];
      for(var t in overlappingTasks) {
          points.add(t.date);
      }
      
      for (var point in points) {
         int count = 0;
         if ((point.isAfter(newTaskStart) || point.isAtSameMomentAs(newTaskStart)) && point.isBefore(newTaskEnd)) {
             count++;
         }
         for (var t in overlappingTasks) {
             final tStart = t.date;
             final tEnd = t.endTime ?? t.date.add(const Duration(hours: 1));
             if ((point.isAfter(tStart) || point.isAtSameMomentAs(tStart)) && point.isBefore(tEnd)) {
                 count++;
             }
         }
         if (count > maxConcurrency) maxConcurrency = count;
      }

      if (maxConcurrency > 3) {
        showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: const Text('Schedule Conflict'),
            content: const Text('You cannot have more than 3 tasks at the same time.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          )
        );
        return;
      }

      final newTask = Task(
        id: _isEditing ? widget.taskToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        category: _selectedCategory,
        date: finalDateTime,
        endTime: finalEndTime,
        isCompleted: _isEditing ? widget.taskToEdit!.isCompleted : false,
        completedAt: _isEditing ? widget.taskToEdit!.completedAt : null,
        mediaPaths: _mediaPaths,
        subtasks: _subtasks,
      );

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F5257), // Header background & selected date
              onPrimary: Colors.white, // Header text & selected date text
              surface: Colors.white, // Background
              onSurface: Colors.black, // Body text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F5257), // Button text
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: const Color(0xFF0F5257),
              headerForegroundColor: Colors.white,
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF0F5257);
                }
                return null;
              }),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black;
              }),
              todayBackgroundColor: WidgetStateProperty.all(const Color(0xFFC8F3F0)),
              todayForegroundColor: WidgetStateProperty.all(const Color(0xFF0F5257)),
              todayBorder: const BorderSide(color: Color(0xFF0F5257), width: 1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return _buildTimePickerTheme(child!);
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        // Reset end time if it becomes invalid? Or just let validation handle it.
      });
    }
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay(hour: _selectedTime.hour + 1, minute: _selectedTime.minute),
      builder: (context, child) {
         return _buildTimePickerTheme(child!);
      },
    );
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  Theme _buildTimePickerTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0F5257),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          primaryContainer: Color(0xFFC8F3F0),
          onPrimaryContainer: Color(0xFF0F5257),
        ),
        timePickerTheme: const TimePickerThemeData(
          helpTextStyle: TextStyle(
            color: Color(0xFF0F5257),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          dialHandColor: Color(0xFF0F5257),
          hourMinuteColor: Color(0xFFC8F3F0),
          hourMinuteTextColor: Color(0xFF0F5257),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0F5257),
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                    _isEditing ? 'Edit Task' : 'Add New Task',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F5257),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Color(0xFF0F5257)),
                    tooltip: 'Smarttingo',
                    onPressed: _openAIAssistant,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'What needs to be done?',
                          hintText: 'e.g., Buy groceries',
                          prefixIcon: const Icon(Icons.task_alt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => 
                            value == null || value.isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Add details...',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Category & Priority Row
                      Row(
                        children: [
                          // Category Select
                          Expanded(
                            child: InkWell(
                              onTap: _showCategoryPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_selectedCategory.icon, size: 20, color: _selectedCategory.color),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedCategory.name,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Priority Selection
                      const Text(
                        'Priority Level',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPriorityOption(TaskPriority.low, 'Low'),
                          const SizedBox(width: 8),
                          _buildPriorityOption(TaskPriority.medium, 'Med'),
                          const SizedBox(width: 8),
                          _buildPriorityOption(TaskPriority.high, 'High'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Date & Time
                      const Text(
                        'Schedule',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(DateFormat('MMM d, y').format(_selectedDate)),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickTime,
                              icon: const Icon(Icons.access_time, size: 18),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(_selectedTime.format(context)),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      // End Time (Optional)
                      InkWell(
                        onTap: _pickEndTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                               Icon(Icons.timer_outlined, size: 18, color: _selectedEndTime != null ? const Color(0xFF0F5257) : Colors.grey),
                               const SizedBox(width: 8),
                               Text(
                                 _selectedEndTime != null 
                                     ? 'Until ${_selectedEndTime!.format(context)}'
                                     : 'Add Deadline (Optional)',
                                 style: TextStyle(
                                   color: _selectedEndTime != null ? const Color(0xFF0F5257) : Colors.grey[600],
                                   fontSize: 14,
                                 ),
                               ),
                               if (_selectedEndTime != null) ...[
                                 const Spacer(),
                                 IconButton(
                                   icon: const Icon(Icons.clear, size: 16),
                                   onPressed: () => setState(() => _selectedEndTime = null),
                                 )
                               ]
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      // Subtasks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtasks',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${_subtasks.length} items',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subtaskController,
                              decoration: const InputDecoration(
                                hintText: 'Add a subtask...',
                                isDense: true,
                              ),
                              onSubmitted: (_) => _addSubtask(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _addSubtask,
                            color: const Color(0xFF0F5257),
                          ),
                        ],
                      ),
                      
                      if (_subtasks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._subtasks.asMap().entries.map((entry) {
                           return Padding(
                             padding: const EdgeInsets.only(bottom: 4),
                             child: Row(
                               children: [
                                 const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                                 const SizedBox(width: 8),
                                 Expanded(child: Text(entry.value.title, style: const TextStyle(fontSize: 14))),
                                 IconButton(
                                   icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                   onPressed: () => setState(() => _subtasks.removeAt(entry.key)),
                                 ),
                               ],
                             ),
                           );
                        }),
                      ],

                      const SizedBox(height: 20),

                      // Media Section
                      const Text(
                        'Media & Attachments',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            InkWell(
                              onTap: _pickImage,
                              child: Container(
                                width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              ),
                            ),
                            ..._mediaPaths.map((path) => Container(
                              width: 60,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _mediaPaths.remove(path)),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 12, color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F5257),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_isEditing ? 'Update Task' : 'Create Task'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isNotEmpty) {
      setState(() {
        _subtasks.add(SubTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _subtaskController.text.trim(),
        ));
        _subtaskController.clear();
      });
    }
  }

  Widget _buildPriorityOption(TaskPriority priority, String label) {
    final isSelected = _selectedPriority == priority;
    Color color;
    switch (priority) {
      case TaskPriority.none:
        color = Colors.grey;
        break;
      case TaskPriority.low:
        color = const Color(0xFF4CAF50);
        break;
      case TaskPriority.medium:
        color = const Color(0xFFFF9800);
        break;
      case TaskPriority.high:
        color = const Color(0xFFF44336);
        break;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriority = priority;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey[200]!,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(image.path);
      final String savedPath = path.join(directory.path, fileName);
      await File(image.path).copy(savedPath);
      setState(() {
        _mediaPaths.add(savedPath);
      });
    }
  }

  Future<void> _openAIAssistant() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Prepare current state
    final Map<String, dynamic> currentState = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category_id': _selectedCategory.id,
      'priority': _selectedPriority.name,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'time': '${_selectedTime.hour}:${_selectedTime.minute}',
      'subtasks': _subtasks.map((s) => s.title).toList(),
    };

    final updates = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AISmartDialog(initialTaskState: currentState),
    );

    if (updates != null && mounted) {
      bool changed = false;
      
      if (updates.containsKey('title')) {
        _titleController.text = updates['title'];
        changed = true;
      }
      
      if (updates.containsKey('description')) {
        _descriptionController.text = updates['description'];
        changed = true;
      }
      
      if (updates.containsKey('category_id')) {
        final catId = updates['category_id'];
        try {
          final cat = taskProvider.categories.firstWhere(
            (c) => c.id == catId,
            orElse: () => _selectedCategory,
          );
          if (cat != _selectedCategory) {
            _selectedCategory = cat;
            changed = true;
          }
        } catch (e) {
            // ignore
        }
      }

      if (updates.containsKey('date')) {
        try {
          final date = DateTime.parse(updates['date']);
          _selectedDate = date;
          changed = true;
        } catch (e) {
           // ignore date parse error
        }
      }

      if (updates.containsKey('time')) {
        try {
          final parts = (updates['time'] as String).split(':');
          if (parts.length == 2) {
            final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
            _selectedTime = time;
            changed = true;
          }
        } catch (e) {
           // ignore
        }
      }
      
      if (updates.containsKey('subtasks')) {
        final List<dynamic> newSubtasks = updates['subtasks'];
        _subtasks = newSubtasks.map((t) => SubTask(
          id: DateTime.now().add(Duration(milliseconds: newSubtasks.indexOf(t))).millisecondsSinceEpoch.toString(),
          title: t.toString(),
        )).toList();
        changed = true;
      }

      if (changed) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated by AI ✨'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0F5257),
          ),
        );
      }
    }
  }

  void _showCategoryPicker() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final categories = taskProvider.categories;
            
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Category',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F5257),
                            ),
                          ),
                          // Add new category button
                          InkWell(
                            onTap: () async {
                              Navigator.pop(bottomSheetContext);
                              await showDialog(
                                context: this.context,
                                builder: (ctx) => const AddCategoryScreen(),
                              );
                              // Refresh after adding
                              setState(() {});
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC8F3F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 18, color: Color(0xFF0F5257)),
                                  SizedBox(width: 4),
                                  Text(
                                    'New',
                                    style: TextStyle(
                                      color: Color(0xFF0F5257),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Tap to select • Long-press to edit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category Grid
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = _selectedCategory.id == category.id;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                              Navigator.pop(bottomSheetContext);
                            },
                            onLongPress: () {
                              // Prevent editing system categories
                              if ([TaskCategory.completed.id, TaskCategory.today.id].contains(category.id)) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(content: Text('System categories cannot be edited')),
                                );
                                return;
                              }
                              
                              Navigator.pop(bottomSheetContext);
                              showDialog(
                                context: this.context,
                                builder: (ctx) => AddCategoryScreen(categoryToEdit: category),
                              ).then((_) {
                                setState(() {});
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? category.color.withValues(alpha: 0.2)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? category.color : Colors.grey[200]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: category.color.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : null,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    // Icon with colored background
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: category.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        category.icon,
                                        size: 20,
                                        color: category.color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13,
                                          color: isSelected ? category.color : Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        size: 20,
                                        color: category.color,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
