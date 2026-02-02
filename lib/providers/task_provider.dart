
import 'dart:convert'; // Added for json encoding
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/task_model.dart';
import '../utils/recurrence_utils.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<TaskCategory> _categories = []; // Custom + Defaults
  TaskCategory? _selectedCategory;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Task> get tasks => _tasks;
  List<TaskCategory> get categories => _categories;
  TaskCategory? get selectedCategory => _selectedCategory;

  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();

  // Completion percentage based on total tasks
  double get completionPercentage {
    if (_tasks.isEmpty) return 0.0;
    return (completedTasks.length / _tasks.length) * 100;
  }

  // --- Productivity Stats ---

  int get totalTasksCount => _tasks.length;
  int get completedTasksCount => completedTasks.length;

  int get currentStreak {
    if (_tasks.isEmpty) return 0;
    
    final completedDates = _tasks
        .where((t) => t.isCompleted && t.completedAt != null)
        .map((t) => DateTime(t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
        .toSet()
        .toList();
    
    if (completedDates.isEmpty) return 0;
    
    completedDates.sort((a, b) => b.compareTo(a)); // Newest first
    
    int streak = 0;
    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    // Check if streak is still active (completed today or yesterday)
    if (!completedDates.contains(today) && !completedDates.contains(today.subtract(const Duration(days: 1)))) {
      return 0;
    }
    
    DateTime currentCheck = today;
    if (!completedDates.contains(today)) {
      currentCheck = today.subtract(const Duration(days: 1));
    }
    
    while (completedDates.contains(currentCheck)) {
      streak++;
      currentCheck = currentCheck.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  Map<TaskPriority, double> get completionRateByPriority {
    Map<TaskPriority, double> rates = {};
    for (var priority in TaskPriority.values) {
      final priorityTasks = _tasks.where((t) => t.priority == priority).toList();
      if (priorityTasks.isEmpty) {
        rates[priority] = 0.0;
      } else {
        final completed = priorityTasks.where((t) => t.isCompleted).length;
        rates[priority] = (completed / priorityTasks.length) * 100;
      }
    }
    return rates;
  }

  Map<TaskPriority, int> get overdueCountByPriority {
    Map<TaskPriority, int> counts = {};
    for (var priority in TaskPriority.values) {
      counts[priority] = _tasks.where((t) => t.priority == priority && t.status == TaskStatus.overdue).length;
    }
    return counts;
  }

  Map<String, double> get completionRateByCategory {
    Map<String, double> rates = {};
    final categoryIds = _tasks.map((t) => t.category.id).toSet();
    for (var catId in categoryIds) {
      final catTasks = _tasks.where((t) => t.category.id == catId).toList();
      final completed = catTasks.where((t) => t.isCompleted).length;
      final categoryName = catTasks.first.category.name;
      rates[categoryName] = (completed / catTasks.length) * 100;
    }
    return rates;
  }

  Map<DateTime, int> getTasksCompletedLast7Days() {
    Map<DateTime, int> trends = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final count = _tasks.where((t) => 
        t.isCompleted && 
        t.completedAt != null && 
        t.completedAt!.year == date.year && 
        t.completedAt!.month == date.month && 
        t.completedAt!.day == date.day
      ).length;
      trends[date] = count;
    }
    return trends;
  }

  List<String> getInsights() {
    List<String> insights = [];
    
    // Priority insight
    final rates = completionRateByPriority;
    if (rates[TaskPriority.high]! < rates[TaskPriority.low]!) {
      insights.add("High-priority tasks are completed less often than low-priority ones.");
    }
    
    // Category insight
    final catRates = completionRateByCategory;
    if (catRates.isNotEmpty) {
      final entries = catRates.entries.toList();
      entries.sort((a, b) => a.value.compareTo(b.value));
      insights.add("${entries.first.key} has the lowest completion rate.");
    }
    
    // Overdue insight
    final overdue = overdueCountByPriority;
    if (overdue[TaskPriority.high]! > 0) {
      insights.add("You have ${overdue[TaskPriority.high]} high-priority tasks overdue.");
    }
    
    if (insights.isEmpty) {
      insights.add("You're doing great! Keep it up.");
    }
    
    return insights.take(3).toList();
  }

  // Get tasks by category
  List<Task> getTasksByCategory(TaskCategory category) {
    if (category.id == TaskCategory.completed.id) {
      return completedTasks;
    }
    return _tasks.where((task) => task.category.id == category.id && !task.isCompleted).toList();
  }

  // Get task count by category
  int getTaskCountByCategory(TaskCategory category) {
     if (category.id == TaskCategory.completed.id) {
      return completedTasks.length;
    }
    return _tasks.where((task) => task.category.id == category.id && !task.isCompleted).length;
  }

  // Get filtered tasks based on selected category
  List<Task> get filteredTasks {
    if (_selectedCategory == null) {
      return pendingTasks;
    }
    if (_selectedCategory!.id == TaskCategory.completed.id) {
      return completedTasks;
    }
    if (_selectedCategory!.id == TaskCategory.today.id) {
      final now = DateTime.now();
      return _tasks.where((task) => 
        task.date.year == now.year && 
        task.date.month == now.month && 
        task.date.day == now.day && 
        !task.isCompleted
      ).toList();
    }
    return _tasks.where((task) => 
      task.category.id == _selectedCategory!.id && !task.isCompleted
    ).toList();
  }

  // Set selected category filter
  void setSelectedCategory(TaskCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  TaskProvider() {
    _audioPlayer.setPlayerMode(PlayerMode.lowLatency); // Enable low latency mode
    _audioPlayer.audioCache.prefix = ''; // Clear default 'assets/' prefix
    _audioPlayer.setSource(AssetSource('assist/audio/success.mp3')); // Pre-load
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCategories();
    await _loadTasks();
  }

  // --- Category Management ---

  void addCategory(TaskCategory category) {
    _categories.add(category);
    _saveCategories();
    notifyListeners();
  }

  void updateCategory(TaskCategory category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      _saveCategories();
      notifyListeners();
      
      // Also update tasks that use this category?
      // Since Task stores a snapshot, yes we should update them to keep UI consistent.
      bool taskUpdated = false;
      for(int i=0; i<_tasks.length; i++) {
          if (_tasks[i].category.id == category.id) {
              _tasks[i] = _tasks[i].copyWith(category: category);
              taskUpdated = true;
          }
      }
      if (taskUpdated) _saveTasks();
    }
  }

  void deleteCategory(String id) {
    // Prevent deleting defaults? 
    if (TaskCategory.defaults.any((c) => c.id == id)) return; // Defaults are hardcoded but also in list?
    // Actually defaults are re-added on load if missing? 
    // Let's assume user creates custom ones. Defaults are static constants.
    
    _categories.removeWhere((c) => c.id == id);
    _saveCategories();
    notifyListeners();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    // Only save custom categories? Or all?
    // Saving all preserves order.
    // Let's allow saving all, but we must ensure defaults are Present on init.
    // Actually, simply saving the list is easier.
    final String encoded = json.encode(_categories.map((c) => c.toMap()).toList());
    await prefs.setString('categories', encoded);
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? categoriesString = prefs.getString('categories');
    
    if (categoriesString != null) {
      final List<dynamic> decoded = json.decode(categoriesString);
      _categories = decoded.map((item) => TaskCategory.fromMap(item)).toList();
    } else {
      // First run: Use defaults
      _categories = List.from(TaskCategory.defaults);
    }
    
    // Ensure Defaults exist (e.g. if we add new defaults in updates)
    // For now we just trust the list or re-merge. 
    // Let's keep it simple.
    notifyListeners();
  }

  // --- Task Management ---

  void addTask(Task task) {
    _tasks.add(task);
    _saveTasks();
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final isNowCompleted = !task.isCompleted;
      
      if (isNowCompleted) {
        _playSuccessSound();
      }

        _tasks[index] = task.copyWith(
          isCompleted: isNowCompleted,
          completedAt: isNowCompleted ? DateTime.now() : null,
          clearCompletedAt: !isNowCompleted, // Clear completedAt when un-completing
        );

        // Handle Recurrence Logo/Loop
        if (isNowCompleted && task.repeatConfig != null) {
          final nextDate = RecurrenceUtils.getNextOccurrence(task);
          if (nextDate != null) {
             // Create clone for next occurrence
             final nextTask = task.copyWith(
               id: DateTime.now().millisecondsSinceEpoch.toString() + "_repeat",
               date: nextDate,
               isCompleted: false,
               clearCompletedAt: true,
               // If there was an end time, calculate its new date too
               endTime: task.endTime != null 
                 ? nextDate.add(task.endTime!.difference(task.date))
                 : null,
               // Decrement occurrences if applicable
               repeatConfig: task.repeatConfig!.occurrences != null 
                 ? RepeatConfig(
                     frequency: task.repeatConfig!.frequency,
                     repeatOn: task.repeatConfig!.repeatOn,
                     repeatMonths: task.repeatConfig!.repeatMonths,
                     interval: task.repeatConfig!.interval,
                     endDate: task.repeatConfig!.endDate,
                     occurrences: task.repeatConfig!.occurrences! - 1,
                   )
                 : task.repeatConfig,
             );
             
             // Add the next instance
             _tasks.add(nextTask);
             
             // Optional: prevent the old task from repeating again if it's edited/untoggled?
             // Usually, once completed, it's a finished instance. 
             // We should probably clear repeatConfig from the COMPLETED task 
             // to signify this specific instance is done and won't trigger another clone if untoggled/retoggled.
             _tasks[index] = _tasks[index].copyWith(clearRepeatConfig: true);
          }
        }

        _saveTasks();
        notifyListeners();
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      // Seek to zero and resume for instant playback (fastest)
      await _audioPlayer.stop(); // Ensure it stops any current playback
      await _audioPlayer.play(AssetSource('assist/audio/success.mp3'));
    } catch (e) {
      debugPrint('Error playing success sound: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = Task.encode(_tasks); 
    await prefs.setString('tasks', encodedData);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString('tasks');
    if (tasksString != null) {
      List<Task> loadedTasks = Task.decode(tasksString);
      
      // Remove completed tasks older than 24 hours
      final now = DateTime.now();
      final cutoffTime = now.subtract(const Duration(hours: 24));
      
      final tasksToRemove = loadedTasks.where((task) {
        if (task.isCompleted && task.completedAt != null) {
          return task.completedAt!.isBefore(cutoffTime);
        }
        return false;
      }).toList();
      
      if (tasksToRemove.isNotEmpty) {
        loadedTasks = loadedTasks.where((task) => !tasksToRemove.contains(task)).toList();
        // Save cleaned list
        final String encodedData = Task.encode(loadedTasks);
        await prefs.setString('tasks', encodedData);
      }
      
      _tasks = loadedTasks;
      notifyListeners();
    }
  }
}




